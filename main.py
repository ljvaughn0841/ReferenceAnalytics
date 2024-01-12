import requests
import json
import os
import pandas as pd
import pprint


def print_dump(raw_response):
    print(json.dumps(raw_response.json(), indent=2))


def create_class_dict(raw_response):
    # pick out the first (primary) teachers name and the course ID to place in a dictionary
    # if there is no teacher for the class we can just forget about it
    output = []
    for course in raw_response.json():
        if course.get('teachers'):
            # teacher = course['teachers'][0]['display_name']
            # teacher = {'name': course['teachers'].display_name()}
            # output.append(teacher)
            # class_id = course['id']
            # print(class_id)
            # class_name = course['name']
            # print(class_name)
            course_data = {'course_id': course['id'],
                           'course_name': course['name'],
                           'instructor': course['teachers'][0]['display_name']
                           }
            output.append(course_data)
    return output


if __name__ == '__main__':
    # Get necessary info for Rest API requests to canvas
    auth_token = os.getenv('AUTHTOKEN')
    headers = {'Authorization': 'Bearer ' + auth_token}
    school_domain_name = "fgcu.instructure.com"

    # request course list with the teachers
    courses_response = requests.get("https://" + school_domain_name + "/api/v1/courses?per_page=100&include[]=teachers",
                                    headers=headers)

    class_dictionary = create_class_dict(courses_response)

    # print(class_dictionary)

    # Time for Assignments and score statistics :)
    # Making a separate table since I think it will be easier to work with
    course_assignments = {}
    for course in class_dictionary:
        assignment_list = requests.get("https://" + school_domain_name + "/api/v1/courses/" + str(course['course_id']) +
                                        "/assignments?per_page=1000&include[]=submission&include[]=score_statistics",
                                        headers=headers).json()

        # print(json.dumps(assignment_list, indent=2))

        if course['course_id'] not in course_assignments:
            course_assignments[course['course_id']] = {}
        # now we save all this info like we did for the classes
        # Data we are after
        #   course[course_id]
        #   "cached_due_date": "2021-02-08T04:59:00Z", ONLY SAVE FIRST 10 DIGITS (remove the exact time)
        #   score_statistics
        #   submission score

        # we have a dictionary for the class using class id
        # In that we have a dictionary for each assignment with the variables like score and such

        for assignment in assignment_list:

            score_stats = assignment.get('score_statistics', {})
            submission_stats = assignment.get('submission', {})

            if submission_stats.get('score') is not None:
                course_assignments[course['course_id']][assignment['name']] = {
                    'due_date': assignment['due_at'],
                    'score': assignment['submission']['score'],
                    'mean': score_stats.get('mean', None),
                    'upper': score_stats.get('upper_q', None),
                }
    pprint.pprint(course_assignments)

    # I'm more familiar with data analysis in R, so I'm exporting some tables to work on there
    # May later add some data analysis here in python if I have time

    # Convert the list of dictionaries to pandas data frame
    df = pd.DataFrame(class_dictionary)
    # Export CSV
    df.to_csv('Class_Data.csv', index=False)

    # Flatten the nested structure for export
    flat_data = []

    for course_id, assignments in course_assignments.items():
        for assignment_name, details in assignments.items():
            row = {
                "CourseID": course_id,
                "AssignmentName": assignment_name,
                "DueDate": details['due_date'],
                "Score": details['score'],
                "Mean": details['mean'],
                "Upper": details['upper']
            }
            flat_data.append(row)

    # Convert to pandas DataFrame
    df = pd.DataFrame(flat_data)

    # Export to CSV
    df.to_csv('course_assignments_data.csv', index=False)

    # Some data chart ideas
    #   a line graph that shows points scored over time ( me vs. the mean or median, and upper quadrant)
    #   standard bar graph of total points
    #   something showing the difference between the submission date and due date
    #   comparison of scores for all classes I had with a professor me vs mean vs upper quadrant
