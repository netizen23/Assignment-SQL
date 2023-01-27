CREATE DATABASE Assignment;

USE Assignment;

CREATE SCHEMA Employee;

CREATE TABLE Employee.Employees (
    EmployeeCode INT NOT NULL,
    FirstName VARCHAR(255) NOT NULL,
    LastName VARCHAR(255) NOT NULL,
    LeaveEntitlement INT NOT NULL,
    LeaveBalance INT NOT NULL,
    PRIMARY KEY (EmployeeCode)
);

CREATE UNIQUE INDEX EmployeeCode_UNIQUE ON Employee.Employees (EmployeeCode);
CREATE TABLE Employee.EmployeeLeaveRecords (
    LeaveRecordID INT NOT NULL AUTO_INCREMENT,
    EmployeeCode INT NOT NULL,
    CalendarYear INT NOT NULL,
    LeaveType VARCHAR(255) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    LeaveVariance INT NOT NULL,
    PRIMARY KEY (LeaveRecordID),
    FOREIGN KEY (EmployeeCode) REFERENCES Employee.Employees (EmployeeCode)
);

CREATE TABLE Employee.EmployeeLeaveBalances (
    EmployeeCode INT NOT NULL,
    TotalLeaveBalance INT NOT NULL,
    PRIMARY KEY (EmployeeCode),
    FOREIGN KEY (EmployeeCode) REFERENCES Employee.Employees (EmployeeCode)
);

CREATE PROCEDURE Employee.add_employees()
BEGIN
	DECLARE done INT DEFAULT FALSE;
	DECLARE emp_code INT;
    DECLARE emp_fname VARCHAR(255);
    DECLARE emp_lname VARCHAR(255);
    DECLARE leave_ent INT;
    DECLARE cur_year INT;
    DECLARE cur CURSOR FOR SELECT EmployeeCode, FirstName, LastName, LeaveEntitlement FROM Employee.Employees;
    DECLARE CONTINUE HANDLER FOR SQLSTATE '23000' SET done = TRUE;
    
    SET cur_year = YEAR(CURRENT_DATE);
    
    INSERT INTO Employee.Employees (EmployeeCode, FirstName, LastName, LeaveEntitlement, LeaveBalance)
    VALUES (1, 'Joseph', 'Bule', 20, 20),
           (2, 'Alice', 'Damane', 20, 20),
           (3, 'Simphiwe', 'Dlamini', 20, 20),
           (4, 'Thabiso', 'Vilakazi', 20, 20),
           (5, 'King', 'Walaza', 20, 20);
           
    OPEN cur;
		read_loop: LOOP
        FETCH cur INTO emp_code, emp_fname, emp_lname, leave_ent;
			IF done THEN
				LEAVE read_loop;
			END IF;   
        
    INSERT INTO Employee.EmployeeLeaveRecords (EmployeeCode, CalendarYear, LeaveType, StartDate, EndDate, LeaveVariance)
        SELECT emp_code, cur_year, 'Annual', DATE_FORMAT(CURRENT_DATE, '%Y-01-01'), DATE_FORMAT(CURRENT_DATE, '%Y-12-31'), leave_ent
        FROM Employee.Employees
        WHERE NOT EXISTS (SELECT 1 FROM Employee.EmployeeLeaveRecords WHERE EmployeeCode = emp_code AND CalendarYear = cur_year);
    END LOOP;
    CLOSE cur;    
 END


CREATE PROCEDURE Employee.add_leave_record(IN emp_code INT, IN start_date DATE, IN end_date DATE)
BEGIN
    DECLARE leave_ent INT;
    DECLARE cur_year INT;
    DECLARE leave_variance INT;
    
    SET cur_year = YEAR(CURRENT_DATE);
    SET leave_variance = DATEDIFF(end_date, start_date);
    SELECT LeaveEntitlement into leave_ent FROM Employee.Employees WHERE EmployeeCode = emp_code;
    
    INSERT INTO Employee.EmployeeLeaveRecords (EmployeeCode, CalendarYear, LeaveType, StartDate, EndDate, LeaveVariance)
    VALUES (emp_code, cur_year, 'Custom', start_date, end_date, leave_variance);
    
    UPDATE Employee.Employees SET LeaveBalance = LeaveBalance - leave_variance WHERE EmployeeCode = emp_code;
END


CREATE TRIGGER update_leave_balance
AFTER INSERT ON Employee.EmployeeLeaveRecords
FOR EACH ROW
BEGIN
    DECLARE leave_variance INT;
    DECLARE leave_balance INT;
    DECLARE emp_code INT;
    SET emp_code = NEW.EmployeeCode;
    SET leave_variance = NEW.LeaveVariance;
    SELECT LeaveBalance INTO leave_balance FROM Employee.Employees WHERE EmployeeCode = emp_code;

    INSERT INTO Employee.EmployeeLeaveBalances(EmployeeCode, TotalLeaveBalance)
    VALUES(emp_code, leave_balance - leave_variance);

    UPDATE Employee.Employees SET LeaveBalance = LeaveBalance - leave_variance WHERE EmployeeCode = emp_code;

END
