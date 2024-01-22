# Reference Analytics Project

## Results
![DEMO1](https://github.com/ljvaughn0841/ReferenceAnalytics/assets/72235620/a0f8bf65-7a06-4828-b2fe-f6717821e72b)
![DEMO2](https://github.com/ljvaughn0841/ReferenceAnalytics/assets/72235620/b7849e97-0a14-4729-b07e-b0ec956e8298)

## DIY Steps
1. Install Python & R. As well as something like R Studio for working with the data and producing graphs.
2. Seting up the Python Script
   * In the Begining of main you will need to replace your auth_token and school_domain_name
   * In Canvas go to Account > Settings > Approved Integrations and press "+ New Access Token" and generate a token to obtain for access to the Canvas's API.
   * Copy the domain name from your canvas URL.
3. Run the Script. It should produce 3 csv files: assignment_groups, Class_Data, and course_assignments_data.
4. Import the datasets into RStudio or whatever you are using for running R.
5. Run the code leading up to graphing to initialize, clean and organize everything.
6. Copy a Course Instructors name from Class Data into instructor name.
   You will need to rerun the initializing instructor_name and instructor courses whenever you want to change the list of courses being graphed.
7. Produce the Cumulative Time and BoxPlot graphs from the for loops below.
   Make sure to go over and check the results. Some teachers organize their grading in strange ways so extra credit or other assignments could be missed or misinterpreted.
