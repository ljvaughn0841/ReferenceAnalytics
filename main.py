import requests
import json
import os
import pandas as pd


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

    # test
    # print_dump(response)

    class_dictionary = create_class_dict(courses_response)

    print(class_dictionary)

    # Convert the list of dictionaries to pandas data frame
    df = pd.DataFrame(class_dictionary)
    # Export CSV
    df.to_csv('Class_Data.csv', index=False)

