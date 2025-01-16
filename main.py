import requests
import json
import os
import pandas as pd
import pprint


def print_dump(raw_response):
    print(json.dumps(raw_response.json(), indent=2))


def create_class_dict(raw_response):
    """
    Reformat the raw JSON response from the Canvas API into a structured list of course dictionaries.

    This function extracts and reorganizes course data to associate courses with their corresponding instructors.

    :param raw_response: Raw JSON response from the Canvas API containing course information,
        including instructors, in the following format:
        {
            "id": int,
            "name": str,
            "teachers": [{"id": int, "display_name": str, ...}, ...],
            ...
        }
    :return: A list of dictionaries, where each dictionary represents a course with the keys:
        - 'course_id' (int): The unique identifier for the course.
        - 'course_name' (str): The name of the course.
        - 'instructors' (list[str]): A list of instructor names associated with the course.
"""
    output = []
    for course in raw_response.json():
        if course.get('teachers'):
            course_data = {'course_id': course['id'],
                           'course_name': course['name'],
                           'instructor': course['teachers'][0]['display_name']
                           }
            output.append(course_data)
    # print(output)
    return output


def create_assignment_dict(course_dict):
    """
    Retrieve assignment information for the given courses.

    :param course_dict: List of dictionaries, where each dictionary represents a course with the keys:
        - 'course_id' (str): The unique identifier for the course.
        - 'course_name' (str): The name of the course.
        - 'instructor' (str): The name of the instructor.
    :return: List of dictionaries representing graded assignments. Each dictionary contains:
        - 'assignment_id' (str): The unique identifier for the assignment.
        - 'course_id' (str): The ID of the course the assignment belongs to.
        - 'title' (str): The title of the assignment.
        - 'due_date' (str): The due date of the assignment in ISO 8601 format.
"""

    course_assignments = {}
    for course in course_dict:
        assignment_list = requests.get("https://" + school_domain_name + "/api/v1/courses/" + str(course['course_id']) +
                                       "/assignments?per_page=1000&include[]=submission&include[]=score_statistics",
                                       headers=headers).json()

        # print(json.dumps(assignment_list, indent=2))

        if course['course_id'] not in course_assignments:
            course_assignments[course['course_id']] = {}

        # now we save all this info like we did for the classes
        # We have a dictionary for the class using class id
        # In that we have a dictionary for each assignment with the variables like score and such

        for assignment in assignment_list:

            score_stats = assignment.get('score_statistics', {})
            submission_stats = assignment.get('submission', {})

            # This is to filter out extra credit or other ungraded assignments that the user didn't complete.
            # Assumes user completes all graded assignments and receives a score for them.
            if submission_stats.get('score') is not None:
                course_assignments[course['course_id']][assignment['name']] = {
                    'due_date': assignment['due_at'],
                    'score': assignment['submission']['score'],
                    'mean': score_stats.get('mean', None),
                    'upper': score_stats.get('upper_q', None),
                    'lower': score_stats.get('lower_q', None),
                    'bottom': score_stats.get('min', None),
                    'top': score_stats.get('max', None),
                    'max': assignment['points_possible'],
                    'group_id': assignment['assignment_group_id'],
                }

    # pprint.pprint(course_assignments)
    return course_assignments


def get_assignment_groups(course_list):
    """
    Retrieve assignment groupings and their weight values for the given courses.

    This function processes a list of courses to extract assignment groupings (e.g., Homework, Exams, Final)
    and their corresponding weight values.

    :param course_list: A list of dictionaries, where each dictionary represents a course with the keys:
        - 'course_id' (int): The unique identifier for the course.
        - 'course_name' (str): The name of the course.
        - 'instructors' (list[str]): A list of instructor names associated with the course.
    :return: A list of dictionaries, where each dictionary contains:
        - 'course_id' (int): The unique identifier for the course.
        - 'group_id' (int): The unique identifier for the assignment group.
        - 'group_name' (str): The name of the assignment group (e.g., Homework, Exams, Final).
        - 'group_weight' (float): The weight of the assignment group as a fraction of the overall grade (out of 100.0).
    """
    group_list = []
    for course in course_list:
        assignment_group_response = requests.get(
            "https://" + school_domain_name + "/api/v1/courses/" + str(course['course_id']) + "/assignment_groups" +
            "?per_page=100", headers=headers)
        for group in assignment_group_response.json():
            group_data = {'course_id': course['course_id'],
                          'group_id': group['id'],
                          'group_name': group['name'],
                          'group_weight': group['group_weight']
                          }
            group_list.append(group_data)
    return group_list


def curate_course_list(course_list, valid_instructors):
    """
    Filter the course list to include only courses taught by specified instructors.

    :param course_list: A list of dictionaries, where each dictionary represents a course with the keys:
        - 'course_id' (int): The unique identifier for the course.
        - 'course_name' (str): The name of the course.
        - 'instructors' (list[str]): A list of instructor names associated with the course.
    :param valid_instructors: A list of instructor names (str) to include in the filtered results.
    :return: A list of dictionaries representing courses taught by the specified instructors.
    """
    filtered_courses = [course for course in course_list if course['instructor'] in valid_instructors]
    return filtered_courses


if __name__ == '__main__':
    # Get necessary info for Rest API requests to canvas
    auth_token = os.getenv('AUTHTOKEN')
    headers = {'Authorization': 'Bearer ' + auth_token}
    school_domain_name = "fgcu.instructure.com"

    # request course list with the teachers
    courses_response = requests.get("https://" + school_domain_name + "/api/v1/courses?per_page=100&include[]=teachers",
                                    headers=headers)

    #print_dump(courses_response)

    class_dictionary = create_class_dict(courses_response)

    # We don't need to collect data on every instructor since a lot of them are Gen Ed
    # TODO: Make this its own function for user input for which instructors to examine.
    class_dictionary = curate_course_list(class_dictionary,
                                          ['Paul Allen', 'Fernando Gonzalez', 'Scott Vanselow', 'Josiah Greenwell'])

    assignment_groups = get_assignment_groups(class_dictionary)

    pprint.pprint(assignment_groups)

    assignments = create_assignment_dict(class_dictionary)

    # TODO: Rather than handle things in R handle them in the python code.
    # Then create web app frontend to make accessible.

    # Convert the list of dictionaries to pandas data frame
    df = pd.DataFrame(class_dictionary)
    # Export CSV
    df.to_csv('Class_Data.csv', index=False)

    # Assignment CSV
    # Flatten the nested structure for export
    flat_data = []

    for course_id, assignments in assignments.items():
        for assignment_name, details in assignments.items():
            row = {
                "course_id": course_id,
                "assignment_name": assignment_name,
                "group_id": details['group_id'],
                "due_date": details['due_date'],
                "score": details['score'],
                "mean": details['mean'],
                "upper": details['upper'],
                "lower": details['lower'],
                "top": details['top'],
                "bottom": details['bottom'],
                "maximum": details['max']
            }
            flat_data.append(row)

    # Convert to pandas DataFrame
    df = pd.DataFrame(flat_data)

    # Export to CSV
    df.to_csv('course_assignments_data.csv', index=False)

    # Converting assignment groups
    df = pd.DataFrame(assignment_groups)
    df.to_csv('assignment_groups.csv', index=False)