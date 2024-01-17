### REFERENCE ANALYTICS SCRIPT ###

# Install and load necessary packages
install.packages("dplyr")
install.packages("ggplot2")
library(dplyr)
library(ggplot2)


# Note: Certain courses might not make statistics freely available.
#       If your getting strange results check to see if the metrics are
#       available for that class.



## FUNCTIONS ##

# Define a function for cumulative totals calculation
# !!! TODO !!! USE TRUE SCORE INSTEAD !!!!
calculate_cumulative_totals <- function(input_data) {
  # Convert 'due_date' to a Date type
  input_data$due_date <- as.Date(input_data$due_date)
  
  # Sort the data by 'due_date' to ensure proper cumulative calculation
  input_data <- input_data %>%
    arrange(due_date)
  
  # Calculate cumulative totals for 'Score', 'Mean', and 'Upper'
  result_data <- input_data %>%
    mutate(
      CumulativeScore = cumsum(Score),
      CumulativeMean = cumsum(Mean),
      CumulativeUpper = cumsum(Upper)
    )
  
  return(result_data)
}



calculate_true_score <- function(course_assignments, assignment_groups) {
  # Calculates the true score value's for assignments in the course.
  #
  # Originally scores don't mean much because the points attributed are relative
  #   to the group. i.e. You can have an exam and a homework assignment both
  #   valued at 10 points.
  
  # Merge course assignments with assignment groups
  # Also helps to remove some assignments groups that don't effect grade
  #   that would otherwise mess up the statistics.
  merged_data <- merge(
    course_assignments,
    assignment_groups,
    by = c("group_id", "course_id"),
    all.x = FALSE
  )
  
  # Calculate the relative score statistics for each assignment
  merged_data$relative_score <- (merged_data$score / merged_data$maximum) * 
    merged_data$group_weight /
    ave(merged_data$group_weight, 
        interaction(merged_data$course_id, 
                    merged_data$group_name, 
                    merged_data$group_weight), 
        FUN = length)
  
  merged_data$relative_mean <- (merged_data$mean / merged_data$maximum) * 
    merged_data$group_weight /
    ave(merged_data$group_weight, 
        interaction(merged_data$course_id, 
                    merged_data$group_name, 
                    merged_data$group_weight), 
        FUN = length)
  
  merged_data$relative_upper <- (merged_data$upper / merged_data$maximum) * 
    merged_data$group_weight /
    ave(merged_data$group_weight, 
        interaction(merged_data$course_id, 
                    merged_data$group_name, 
                    merged_data$group_weight), 
        FUN = length)
  
  merged_data$relative_lower <- (merged_data$lower / merged_data$maximum) * 
    merged_data$group_weight /
    ave(merged_data$group_weight, 
        interaction(merged_data$course_id, 
                    merged_data$group_name, 
                    merged_data$group_weight), 
        FUN = length)
  
  return(merged_data)
}





## DATA ORGANIZATION / CLEANING ##

### NEEDS TO BE REFRACTORED DUE TO NEW TRUE SCORE ###

## TESTING B4 AUTOMATING FUNCTION ##
merged_data <- merge(
  course_assignments_data,
  assignment_groups,
  by = c("group_id", "course_id"),
  all.x = FALSE
)


CEN3073 <- split_assignments$'529829'

testCEN <- calculate_true_score(CEN3073, assignment_groups)

ave(CEN3073$group_weight, CEN3073$group_weight, FUN = length)

sum(testCEN$relative_mean)
sum(testCEN$relative_upper)
sum(testCEN$relative_lower)


# TEST GROUP STUFF
split_assignments <- split(course_assignments_data, course_assignments_data$course_id)


for(course in split_assignments) {
  calculate_true_score(course, assignment_groups)
}

for (course_id in names(split_assignments)) {
  # Extract the course assignments for the current course_id
  course <- split_assignments[[course_id]]
  
  # Retrieve the assignment_groups for the current course_id
  current_assignment_groups <- subset(assignment_groups, course_id == unique(course$course_id))
  
  # Check if there are assignment groups for the current course_id
  if (nrow(current_assignment_groups) > 0) {
    # Calculate true scores for the current course
    updated_course <- calculate_true_score(course, current_assignment_groups)
    
    # Update the split_assignments with the calculated true scores
    split_assignments[[course_id]] <- updated_course
  } else {
    # Handle the case where there are no assignment groups for the current course_id
    warning(paste("No assignment groups found for course_id:", course_id))
  }
}

# testing sum of id
sum(split_assignments[[as.character(529829)]]$relative_upper)



# stuff

result <- calculate_cumulative_totals(CEN3073)

result_long <- result %>%
  gather(key = "ScoreType", value = "CumulativeValue", CumulativeScore, CumulativeMean, CumulativeUpper) %>%
  mutate(ScoreType = ifelse(ScoreType == "CumulativeScore", "My Score", ScoreType))


### GRAPHING ###



## TIME GRAPH ##
# Plot the cumulative sums over time
ggplot(result, aes(x = due_date)) +
  geom_line(aes(y = CumulativeScore,
                color = "MyScore"),
            linetype = "solid",
            size = 1) +
  geom_line(aes(y = CumulativeMean,
                color = "Mean"),
            linetype = "dashed",
            size = 1) +
  geom_line(aes(y = CumulativeUpper,
                color = "Upper"),
            linetype = "dotted",
            size = 1) +
  labs(title = "CEN3073 Cumalitive Score over Time",
       x = "Date",
       y = "Cumulative Score",
       color = "") +
  theme_minimal()+
  theme(legend.position = "bottom")+
  scale_color_manual(values = c(MyScore = "blue", Mean = "green", Upper = "red"),
                     labels = c(MyScore = "My Score", Mean = "Class Mean", Upper = "Upper Quadrant")) +
  coord_cartesian(xlim = c(max(result$due_date) - 80, max(result$due_date)),
                  ylim = c(0, 400))




