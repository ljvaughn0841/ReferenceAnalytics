### REFERENCE ANALYTICS SCRIPT ###

# Install and load necessary packages
install.packages("dplyr")
install.packages("ggplot2")
install.packages("tidyr")
library(dplyr)
library(ggplot2)
library(tidyr)

# Note: Certain courses might not make statistics freely available.
#       If your getting strange results check to see if the metrics are
#       available for that class.



## FUNCTIONS ##


calculate_true_score <- function(course_assignments, assignment_groups) {
  # Calculates the relative score value's for assignments in the course.
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



# Define a function for cumulative totals calculation
calculate_cumulative_totals <- function(input_data) {
  # Convert 'due_date' to a Date type
  input_data$due_date <- as.Date(input_data$due_date)
  
  # Sort the data by 'due_date' to ensure proper cumulative calculation
  input_data <- input_data %>%
    arrange(due_date)
  
  # Calculate cumulative totals for relative 'score', 'mean', and 'upper'
  result_data <- input_data %>%
    mutate(
      cumulative_score = cumsum(replace_na(relative_score, 0)),
      cumulative_mean = cumsum(replace_na(relative_mean, 0)),
      cumulative_upper = cumsum(replace_na(relative_upper, 0))
    )
  
  return(result_data)
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
    
    
    updated_course$relative_score <- replace(updated_course$relative_score, 
                                             is.infinite(updated_course$relative_score), 0)
    
    
    # Update the split_assignments with the calculated true scores
    split_assignments[[course_id]] <- updated_course
  } else {
    # Handle the case where there are no assignment groups for the current course_id
    warning(paste("No assignment groups found for course_id:", course_id))
  }
}

# testing sum of id
sum(replace_na(split_assignments[[as.character(534512)]]$relative_mean, 0))


for (i in seq_along(split_assignments)) {
  split_assignments[[i]] <- calculate_cumulative_totals(split_assignments[[i]])
}

### GRAPHING ###

# Add the instructors name for their classes to be plotted
instructor_name <- ""

# Find the unique course_ids associated with the instructor
instructor_courses <- unique(Class_Data$course_id[Class_Data$instructor == instructor_name])


for (course_id in instructor_courses) {
  
  result <- split_assignments[[as.character(course_id)]]
  
  
  # Extract the corresponding course_name
  course_name <- Class_Data$course_name[Class_Data$course_id == course_id][1]
  
  # Extract the part after the final "-" mark
  course_name <- tail(strsplit(course_name, " - ")[[1]], 1)

  ## TIME GRAPH ##
  # Plot the cumulative sums over time
  ggplot_time <- ggplot(result, aes(x = due_date)) +
    geom_line(aes(y = cumulative_score,
                  color = "MyScore"),
              linetype = "solid",
              linewidth = 1) +
    geom_line(aes(y = cumulative_mean,
                  color = "Mean"),
              linetype = "dashed",
              linewidth = 1) +
    geom_line(aes(y = cumulative_upper,
                  color = "Upper"),
              linetype = "dotted",
              linewidth = 1) +
    labs(title = paste(course_name, "Cumalitive Score over Time -", instructor_name),
         x = "Date",
         y = "Cumulative Score",
         color = "") +
    theme_minimal()+
    theme(legend.position = "bottom")+
    scale_color_manual(values = c(MyScore = "blue", Mean = "green", Upper = "red"),
                       labels = c(MyScore = "My Score", Mean = "Class Mean", Upper = "Upper Quadrant")) +
    coord_cartesian(ylim = c(0, 100))
  # xlim = c(max(result$due_date) - 100, max(result$due_date)),
  print(ggplot_time)
  
}



## IDEAS
# Cumulative sums showing which teacher was my best teacher
# In that i was the highest above or closest to the upper quadrant

# Boxplots showing how assignments performed for everyone
# with geom points above that showing my performance






