
  
//**************************** Data **************************************
int totalPeriods = ...; // Total # of Periods in a day
int NbPeriods = ...;    // Total # Periods a person should have class in a day
int numRooms = 8;	// Total # of classrooms

range Periods = 1..totalPeriods;
{string} Professors = ...;     // Set of Professors
{string} Weekdays = ...;   // Set of work days 
{string} Rooms = ...;     // Set of Rooms
{string} Courses = ...;    // Set of Courses
float CoursePrefs[j in Professors][c in Courses] = ...;
float PeriodPrefs[p in Periods][c in Courses] = ...;


// Data Structure
// List of Professors/Courses
tuple LCourse {
	string LC;
  {string} LDay;

}

// HardSign
tuple Sign
{
int PA;
{string} WA;
string PrA;
string RA;
string CA;
}

{Sign} HardSign = ...;	// List of Courses that must be assigned in manually
{LCourse} LongCourses = ...; //  List of Professors for each course
int Penalty = card(Weekdays)*NbPeriods+1; // Penalty for an unfilled slot
//********************************* Variables **********************************
        
dvar boolean Assign[Weekdays][Periods][Rooms][Professors][Courses];   // Indicates a course assignment
dvar boolean Avail[Weekdays][Periods][Rooms][Courses];     // Indicates the availability of a room
/************************************* Model *********************************/

maximize sum(j in Professors, c in Courses, r in Rooms, w in Weekdays, p in Periods) Assign[w,p,r,j,c]*(CoursePrefs[j,c])*PeriodPrefs[p,c];


subject to {
	// Assign a professor to teach a course in a specific time and room
	forall(h in HardSign)
		forall (w in h.WA) 
			Assign[w][h.PA][h.RA][h.PrA][h.CA] ==1;
	
	// Assign only 1 professor per room/period 
   	forall(w in Weekdays, p in Periods, r in Rooms, c in Courses)
     		sum(j in Professors)
        		Assign[w][p][r][j][c] <= 1;
	
	forall(w in Weekdays, p in Periods, r in Rooms)
   		sum(j in Professors, c in Courses) 
			Assign[w][p][r][j][c] <= 1;
		
	// Assign 1 prof/course combo per timeslot
  	forall (c in LongCourses)
    		forall (w in c.LDay)
    		sum (p in Periods, j in Professors, r in Rooms) Assign[w][p][r][j][c.LC] == 1;
  
  	forall (w in Weekdays, c in Courses, j in Professors, r in Rooms)
    		sum (p in Periods) Assign[w][p][r][j][c]<=1;
	
	// A course is taught once per period
  	forall (w in Weekdays, p in Periods, r in Rooms)
    		sum (c in Courses) Avail[w][p][r][c] <= 1;
  
  	// Check professor availability 
  	forall (w in Weekdays, p in Periods, r in Rooms, c in Courses)
    		sum (j in Professors) Assign[w][p][r][j][c] <= Avail[w][p][r][c];
	
 	forall(j in Professors, w in Weekdays, p in Periods)
   		sum (c in Courses, r in Rooms) Assign[w][p][r][j][c] <= 1;
   	
	// Same period, room, course, and professor on Mondays and Wednesdays
   	forall (c in Courses, p in 1..5, r in Rooms, j in Professors)
		Assign["Mon"][p][r][j][c] == Assign["Wed"][p][r][j][c];
	    
	// Fridays does not have long time period classes (Long period classes only taught on Mondays and Wednesdays) 
	forall (c in Courses, p in 1..4, r in Rooms, j in Professors) 
		Assign["Fri"][p][r][j][c] == Assign["Mon"][p][r][j][c];
	
	// No classes after the fourth period on Fridays
	forall(c in Courses, r in Rooms, j in Professors)
		Assign["Fri"][5][r][j][c] == 0;

	// Set availability to 1 course per room/period  
	forall(w in Weekdays, p in Periods, r in Rooms)
      		sum(c in Courses)
         		Avail[w][p][r][c] <= 1;
}

main{

	thisOplModel.generate();
	cplex.solve();     
 	var f = new IloOplOutputFile("output.txt");
   	f.writeln(thisOplModel.printSolution());
  	f.close();   
}
