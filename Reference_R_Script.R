### REFERENCE ANALYTICS SCRIPT ###

# Install and load necessary packages
install.packages("dplyr")
install.packages("ggplot2")
install.packages("tidyr")
install.packages("reshape2")
library(dplyr)
library(ggplot2)
library(tidyr)
library(reshape2)

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



calculate_individual_scores <- function(merged_data) {
  # Calculates the scores individually for their category
  # The maximum possible scores in each category will total to 100.
  # This individual score is intended to separate grade value from 
  #   the groups of assignments. (like tests and homework)
  
  # Calculate the relative score statistics for each assignment
  merged_data$individual_score <- (merged_data$score / merged_data$maximum) * 
    100
  
  merged_data$individual_mean <- (merged_data$mean / merged_data$maximum) * 
    100
  
  merged_data$individual_upper <- (merged_data$upper / merged_data$maximum) * 
    100
  
  merged_data$individual_lower <- (merged_data$lower / merged_data$maximum) * 
    100
  
  merged_data$individual_top <- (merged_data$top / merged_data$maximum) * 
    100
  
  merged_data$individual_bottom <- (merged_data$bottom / merged_data$maximum) * 
    100
  
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
      cumulative_upper = cumsum(replace_na(relative_upper, 0)),
      cumulative_lower = cumsum(replace_na(relative_lower, 0))
    )
  
  return(result_data)
}


## DATA ORGANIZATION / CLEANING ##

# Splitting assignments data into split tables by course ID
split_assignments <- split(course_assignments_data, course_assignments_data$course_id)

# Adding relative scores to split_assignments
#   Relative scores use the weight and assignment groups to find the 
#     true value an assignments has relative to the entire class grade.
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

# Adding cumulative sums (by Date) into split_assignments
for (i in seq_along(split_assignments)) {
  split_assignments[[i]] <- calculate_cumulative_totals(split_assignments[[i]])
}




# Adding Individual Scores
#   Individual Scores: separating the weight from assignment groups. 
#     Such that each assignment group is worth 100 points total.
for (course_id in names(split_assignments)) {
  # Extract the course assignments for the current course_id
  course <- split_assignments[[course_id]]
  
  # Retrieve the assignment_groups for the current course_id
  current_assignment_groups <- subset(assignment_groups, course_id == unique(course$course_id))
  
  # Check if there are assignment groups for the current course_id
  if (nrow(current_assignment_groups) > 0) {
    # Calculate true scores for the current course
    updated_course <- calculate_individual_scores(course)
    
    
    updated_course$individual_score <- replace(updated_course$individual_score, 
                                               is.infinite(updated_course$individual_score), 0)
    
    
    # Update the split_assignments with the calculated true scores
    split_assignments[[course_id]] <- updated_course
  } else {
    # Handle the case where there are no assignment groups for the current course_id
    warning(paste("No assignment groups found for course_id:", course_id))
  }
}



### GRAPHING ###
# Graphing is done by teacher in order to keep things organized.
# Certain grading methods may introduce complications so it's best to
# thoroughly look over the results to make sure that they are accurate.


# Add the instructors name for their classes to be plotted
instructor_name <- "YOUR TEACHERS NAME FROM CLASS_DATA"

# Find the unique course_ids associated with the instructor
instructor_courses <- unique(Class_Data$course_id[Class_Data$instructor == instructor_name])


## TIME GRAPH ##
for (course_id in instructor_courses) {
  
  course_table <- split_assignments[[as.character(course_id)]]
  
  
  # Extract the corresponding course_name
  course_name <- Class_Data$course_name[Class_Data$course_id == course_id][1]
  
  # Extract the part after the final "-" mark
  course_name <- tail(strsplit(course_name, " - ")[[1]], 1)

  # Plot the cumulative sums over time
  ggplot_time <- ggplot(course_table, aes(x = due_date)) +
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
    geom_line(aes(y = cumulative_lower,
                  color = "Lower"),
              linetype = "dotted",
              linewidth = 1) +
    labs(title = paste(course_name, "Cumalitive Score over Time -", instructor_name),
         x = "Date",
         y = "Cumulative Score",
         color = "") +
    theme_minimal()+
    theme(legend.position = "bottom")+
    scale_color_manual(values = c(MyScore = "blue", Mean = "green", Upper = "red", Lower = "orange"),
                       labels = c(MyScore = "My Score", Mean = "Class Mean", Upper = "Upper Quadrant", Lower = "Lower Quadrant")) +
    coord_cartesian(
      ylim = c(0, 100))
  # xlim = c(max(course_table$due_date) - 100, max(course_table$due_date)),
  print(ggplot_time)
  
}


## BOX PLOT ##
# Boxplots showing how assignments performed for everyone
# with geom points above that showing my performance

for(course_id in instructor_courses){
  course_table <- split_assignments[[as.character(course_id)]]
  
  
  # Extract the corresponding course_name
  course_name <- Class_Data$course_name[Class_Data$course_id == course_id][1]
  
  # Extract the part after the final "-" mark
  course_name <- tail(strsplit(course_name, " - ")[[1]], 1)
  
  
  # Calculate total average for individually scored assignment groups
  cumulative_avg <- aggregate(cbind(individual_upper, 
                                    individual_lower, 
                                    individual_mean, 
                                    individual_top, 
                                    individual_bottom,
                                    individual_score) 
                              ~ group_name, course_table, mean)
  
  gg_boxplot <- ggplot(cumulative_avg, aes(x = group_name, fill = group_name)) +
    geom_boxplot(
      aes(lower=individual_lower,
          middle = individual_mean,
          upper= individual_upper,
          ymin = individual_bottom,
          ymax = individual_top),
      stat = "identity") +
    labs(title = paste("Average Scores by Category for", course_name, "-", instructor_name),
         x = "Assignment Category",
         y = "Average Score") +
    theme_minimal() +
    guides(fill = FALSE) + 
    geom_point(aes(x = group_name, y = individual_score), shape = 21,
               color = "black", fill = "white", size = 3, stroke = 2) +
    annotate(
      "text",
      x = 2 ,  # Adjust the x-coordinate as needed
      y = max(cumulative_avg$individual_score) + 5,  # Adjust the y-coordinate as needed
      label = "My Average Scores are Represented on the Points",
      color = "black"
    )
  
  print(gg_boxplot)
}

