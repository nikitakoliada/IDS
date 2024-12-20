BEGIN
    DECLARE
        table_count NUMBER;
        view_count  NUMBER;
    BEGIN
        SELECT COUNT(*) INTO table_count FROM USER_TABLES;
        SELECT COUNT(*) INTO view_count FROM USER_MVIEWS;
        IF view_count > 0 THEN
            EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW XKOLIA00.Consent_View';
            EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW PERFORMANCE_MONITORING';
        end if;
        IF table_count > 0 THEN
            EXECUTE IMMEDIATE 'DROP TABLE Children CASCADE CONSTRAINTS';
            EXECUTE IMMEDIATE 'DROP TABLE Adults CASCADE CONSTRAINTS';
            EXECUTE IMMEDIATE 'DROP TABLE Classes CASCADE CONSTRAINTS';
            EXECUTE IMMEDIATE 'DROP TABLE WorksAs CASCADE CONSTRAINTS';
            EXECUTE IMMEDIATE 'DROP TABLE TakingPeople CASCADE CONSTRAINTS';
            EXECUTE IMMEDIATE 'DROP TABLE Teachers CASCADE CONSTRAINTS';
            EXECUTE IMMEDIATE 'DROP TABLE Parents CASCADE CONSTRAINTS';
            EXECUTE IMMEDIATE 'DROP TABLE Guidance CASCADE CONSTRAINTS';
            EXECUTE IMMEDIATE 'DROP TABLE GuidanceRejections CASCADE CONSTRAINTS';
            EXECUTE IMMEDIATE 'DROP TABLE Consents CASCADE CONSTRAINTS';
            EXECUTE IMMEDIATE 'DROP TABLE ConsentRejections CASCADE CONSTRAINTS';
            EXECUTE IMMEDIATE 'DROP TABLE ChildIsInClass CASCADE CONSTRAINTS';
            EXECUTE IMMEDIATE 'DROP SEQUENCE Classes_idSequence';
            EXECUTE IMMEDIATE 'DROP SEQUENCE Guidance_idSequence';
            EXECUTE IMMEDIATE 'DROP SEQUENCE Consents_idSequence';
            EXECUTE IMMEDIATE 'DROP SEQUENCE Works_idSequence';
        end if;
    END;
END;


CREATE SEQUENCE Classes_idSequence
    INCREMENT BY 1
    START WITH 0
    MINVALUE 0
    NOMAXVALUE;

CREATE SEQUENCE Works_idSequence
    INCREMENT BY 1
    START WITH 0
    MINVALUE 0
    NOCACHE;

CREATE SEQUENCE Consents_idSequence
    INCREMENT BY 1
    START WITH 0
    MINVALUE 0
    NOCACHE;

CREATE SEQUENCE Guidance_idSequence
    INCREMENT BY 1
    START WITH 0
    MINVALUE 0
    NOMAXVALUE;

CREATE TABLE Children
(
    Id         CHAR(11),
    FirstName  VARCHAR(20),
    SecondName VARCHAR(20),
    Birthday   DATE,
    Sex        CHAR(1),
    City       VARCHAR(30),
    Address    VARCHAR(50)
);

-- Generalizace --
-- Adult je predek
-- Teacher, TakingPerson i Parent jsou potomky
-- Generalizace je implementovana zde pomoci cizich klici
-- Pri vytvoreni entity Teacher je treba na pocatku vytvorit entitu Adult, vyplnit jeho honoty
-- Pote vytvorit Teacher a priradit mu do Id hodnotu Id entity Adult

CREATE TABLE Adults
(
    Id          CHAR(11),
    FirstName   VARCHAR(20),
    SecondName  VARCHAR(20),
    Birthday    DATE,
    Sex         CHAR(1),
    Address     VARCHAR(50),
    City        VARCHAR(30),
    PhoneNumber CHAR(20),
    Email       VARCHAR(20)
);

CREATE TABLE TakingPeople
(
    Id CHAR(11)
);

CREATE TABLE Teachers
(
    Id CHAR(11)
);

CREATE TABLE Parents
(
    Id CHAR(11)
);

CREATE TABLE Classes
(
    Id        INTEGER DEFAULT Classes_idSequence.NEXTVAL,
    Name      VARCHAR(20),
    Classroom VARCHAR(5)
);

CREATE TABLE WorksAs
(
    WorkId    INTEGER DEFAULT Works_idSequence.NEXTVAL,
    TeacherId CHAR(11) NOT NULL,
    ClassId   INT      NOT NULL,
    Position  CHAR(10),
    StartTime TIMESTAMP,
    EndTime   TIMESTAMP,
    DayOfWeek VARCHAR(10)
);

CREATE TABLE Guidance
(
    GuidanceId     INTEGER DEFAULT Guidance_idSequence.NEXTVAL,
    ChildId        CHAR(11),
    ParentId       CHAR(11),
    TakingPersonId CHAR(11),
    SignatureDate  DATE,
    Activity       VARCHAR(20),
    State          VARCHAR(10)
);

CREATE TABLE GuidanceRejections
(
    ChildId       CHAR(11),
    GuidanceId    INT,
    ParentId      CHAR(11),
    SignatureDate DATE
);

CREATE TABLE Consents
(
    ConsentId     INTEGER DEFAULT Consents_idSequence.NEXTVAL,
    ChildId       CHAR(11),
    ParentId      CHAR(11),
    SignatureDate DATE,
    Activity      VARCHAR(20),
    State         VARCHAR(10)
);

CREATE TABLE ConsentRejections
(
    ChildId       CHAR(11),
    ConsentId     INT,
    ParentId      CHAR(11),
    SignatureDate DATE
);

CREATE TABLE ChildIsInClass
(
    ChildId   CHAR(11),
    ClassId   INT,
    StartDate DATE,
    EndData   DATE
);

ALTER TABLE Children
    ADD CONSTRAINT PK_Child PRIMARY KEY (Id);
ALTER TABLE Children
    ADD CONSTRAINT Check_IdChild CHECK ( REGEXP_LIKE(Id, '^\d{6}/\d{4}$') );
ALTER TABLE Children
    ADD CONSTRAINT Check_SexChild CHECK ( Sex in ('M', 'F') );

ALTER TABLE Adults
    ADD CONSTRAINT Pk_Adult PRIMARY KEY (Id);
ALTER TABLE Adults
    ADD CONSTRAINT Check_IdAdult CHECK ( REGEXP_LIKE(Id, '^[0-9]{6}/[0-9]{4}$') );
ALTER TABLE Adults
    ADD CONSTRAINT Check_SexAdult CHECK ( Sex in ('M', 'F') );
ALTER TABLE Adults
    ADD CONSTRAINT Check_EmailAdult CHECK ( REGEXP_LIKE(Email, '^[a-zA-Z0-9._-]+@[a-zA-Z0-9_.-]+\.[a-zA-Z]{2,}$') );
ALTER TABLE Adults
    ADD CONSTRAINT Unique_AdultEmail UNIQUE (Email);
ALTER TABLE Adults
    ADD CONSTRAINT Unique_AdultNumber UNIQUE (PhoneNumber);

ALTER TABLE TakingPeople
    ADD CONSTRAINT Pk_TakingPerson PRIMARY KEY (Id);
ALTER TABLE TakingPeople
    ADD CONSTRAINT Fk_TakingPersonAdult FOREIGN KEY (Id)
        REFERENCES Adults (Id) ON DELETE CASCADE;

ALTER TABLE Teachers
    ADD CONSTRAINT Pk_Teacher PRIMARY KEY (Id);
ALTER TABLE Teachers
    ADD CONSTRAINT Fk_TeacherAdult FOREIGN KEY (Id)
        REFERENCES Adults (Id) ON DELETE CASCADE;

ALTER TABLE Parents
    ADD CONSTRAINT Pk_Parent PRIMARY KEY (Id);
ALTER TABLE Parents
    ADD CONSTRAINT Fk_ParentAdult FOREIGN KEY (Id)
        REFERENCES Adults (Id) ON DELETE CASCADE;

ALTER TABLE Classes
    ADD CONSTRAINT Pk_Class PRIMARY KEY (Id);

ALTER TABLE WorksAs
    ADD CONSTRAINT Pk_WorksAs PRIMARY KEY (TeacherId, ClassId, Position, WorkId);
ALTER TABLE WorksAs
    ADD CONSTRAINT Fk_Teacher FOREIGN KEY (TeacherId)
        REFERENCES Teachers (Id);
ALTER TABLE WorksAs
    ADD CONSTRAINT Fk_Class FOREIGN KEY (ClassId)
        REFERENCES Classes (Id);
ALTER TABLE WorksAs
    ADD CONSTRAINT Interval_Check CHECK ( EndTime > StartTime );
ALTER TABLE WorksAs
    ADD CONSTRAINT Interval_DayOfWeek CHECK ( UPPER(DayOfWeek)
        IN ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') );

ALTER TABLE Guidance
    ADD CONSTRAINT Pk_Guidance PRIMARY KEY (ChildId, GuidanceId);
ALTER TABLE Guidance
    ADD CONSTRAINT Fk_GuidanceChild FOREIGN KEY (ChildId)
        REFERENCES Children (Id) ON DELETE CASCADE;
ALTER TABLE Guidance
    ADD CONSTRAINT Fk_GuidanceParent FOREIGN KEY (ParentId)
        REFERENCES Parents (Id);
ALTER TABLE Guidance
    ADD CONSTRAINT Fk_GuidanceTakingPerson FOREIGN KEY (TakingPersonId)
        REFERENCES TakingPeople (Id);

ALTER TABLE GuidanceRejections
    ADD CONSTRAINT Pk_GuidanceRejection
        PRIMARY KEY (ChildId, GuidanceId, ParentId);
ALTER TABLE GuidanceRejections
    ADD CONSTRAINT Fk_GuidanceRejection FOREIGN KEY (ChildId, GuidanceId)
        REFERENCES Guidance (ChildId, GuidanceId) ON DELETE CASCADE;
ALTER TABLE GuidanceRejections
    ADD CONSTRAINT Fk_GuidanceRejectionParent FOREIGN KEY (ParentId)
        REFERENCES Parents (Id);

ALTER TABLE Consents
    ADD CONSTRAINT Pk_Consent PRIMARY KEY (ChildId, ConsentId);
ALTER TABLE Consents
    ADD CONSTRAINT Fk_ConsentChild FOREIGN KEY (ChildId)
        REFERENCES Children (Id) ON DELETE CASCADE;
ALTER TABLE Consents
    ADD CONSTRAINT Fk_ConsentParent FOREIGN KEY (ParentId)
        REFERENCES Parents (Id);

ALTER TABLE ConsentRejections
    ADD CONSTRAINT Pk_ConsentRejection
        PRIMARY KEY (ChildId, ConsentId, ParentId);
ALTER TABLE ConsentRejections
    ADD CONSTRAINT Fk_ConsentRejection FOREIGN KEY (ChildId, ConsentId)
        REFERENCES Consents (ChildId, ConsentId) ON DELETE CASCADE;
ALTER TABLE ConsentRejections
    ADD CONSTRAINT Fk_ConsentRejectionParent FOREIGN KEY (ParentId)
        REFERENCES Parents (Id);

ALTER TABLE ChildIsInClass
    ADD CONSTRAINT Pk_ChildIsInClass PRIMARY KEY (ChildId, ClassId);
ALTER TABLE ChildIsInClass
    ADD CONSTRAINT Fk_ChildIsInClassChild FOREIGN KEY (ChildId)
        REFERENCES Children (Id);
ALTER TABLE ChildIsInClass
    ADD CONSTRAINT Fk_ChildIsInClassClass FOREIGN KEY (ClassId)
        REFERENCES Classes (Id);
ALTER TABLE ChildIsInClass
    ADD CONSTRAINT Check_ChildsAttendance CHECK ( EndData > StartDate );


INSERT INTO Adults
(Id, FirstName, SecondName, Birthday, Sex, City, Address, PhoneNumber, Email)
VALUES ('044400/0900', 'Peter', 'Parker', date '1980-09-09', 'M', 'Brno',
        'Videnska, 4', '+42054545454', 'email@email.com');

INSERT INTO Teachers (Id)
VALUES ('044400/0900');

INSERT INTO Adults
(Id, FirstName, SecondName, Birthday, Sex, City, Address, PhoneNumber, Email)
VALUES ('044477/0904', 'Oskar', 'Dolezal', date '1994-09-03', 'M', 'Kurim',
        'Kolejni, 455', '+42050976543', 'oskar@email.com');

INSERT INTO Teachers (Id)
VALUES ('044477/0904');

INSERT INTO Adults
(Id, FirstName, SecondName, Birthday, Sex, City, Address, PhoneNumber, Email)
VALUES ('045500/0967', 'Mary', 'Parker', date '1990-11-11', 'F',
        'Brno', 'Videnska, 4', '+420545454', 'ydail@email.com');

INSERT INTO Parents (Id)
VALUES ('045500/0967');

INSERT INTO Adults
(Id, FirstName, SecondName, Birthday, Sex, City, Address, PhoneNumber, Email)
VALUES ('349930/0465', 'Borivoj', 'Jelinek', date '1984-07-25', 'M',
        'Slavkov u Brna', 'Kartouzska, 21', '+42012334553', 'jelinek@email.com');

INSERT INTO Parents (Id)
VALUES ('349930/0465');

INSERT INTO Adults
(Id, FirstName, SecondName, Birthday, Sex, City, Address, PhoneNumber, Email)
VALUES ('999999/9967', 'Ann', 'Gonzales', date '1983-10-11', 'F', 'Brno',
        'Pionyrska, 6', '+4205445454', 'ydtgil@eftil.com');

INSERT INTO TakingPeople (Id)
VALUES ('999999/9967');

INSERT INTO Adults
(Id, FirstName, SecondName, Birthday, Sex, City, Address, PhoneNumber, Email)
VALUES ('897789/9961', 'Klotylda', 'Polak', date '2000-12-13', 'F', 'Modrice',
        'Havlickova, 88', '+42000343454', 'polak@seznam.cz');

INSERT INTO TakingPeople (Id)
VALUES ('897789/9961');

INSERT INTO Classes (Id, Name, Classroom)
VALUES (1, 'Space', 'A75');
INSERT INTO Classes (Id, Name, Classroom)
VALUES (2, 'Champion', 'G44');
INSERT INTO Classes (Name, Classroom)
VALUES ('Rainbow', 'B01');

INSERT INTO WorksAs (WorkId, TeacherId, ClassId, Position, StartTime, EndTime, DayOfWeek)
VALUES (0, '044400/0900', 1, 'Assistant', TO_TIMESTAMP('10:30:00', 'HH24:MI:SS'),
        TO_TIMESTAMP('17:30:00', 'HH24:MI:SS'), 'Monday');
INSERT INTO WorksAs (WorkId, TeacherId, ClassId, Position, StartTime, EndTime, DayOfWeek)
VALUES (0, '044400/0900', 2, 'Teacher', TO_TIMESTAMP('13:10:00', 'HH24:MI:SS'),
        TO_TIMESTAMP('18:30:00', 'HH24:MI:SS'), 'Wednesday');

INSERT INTO WorksAs (WorkId, TeacherId, ClassId, Position, StartTime, EndTime, DayOfWeek)
VALUES (0, '044477/0904', 1, 'Teacher', TO_TIMESTAMP('08:00:00', 'HH24:MI:SS'),
        TO_TIMESTAMP('12:55:00', 'HH24:MI:SS'), 'Friday');
INSERT INTO WorksAs (WorkId, TeacherId, ClassId, Position, StartTime, EndTime, DayOfWeek)
VALUES (1, '044477/0904', 1, 'Teacher', TO_TIMESTAMP('08:00:00', 'HH24:MI:SS'),
        TO_TIMESTAMP('12:55:00', 'HH24:MI:SS'), 'Tuesday');

INSERT INTO Children (Id, FirstName, SecondName, Birthday, Sex, City, Address)
VALUES ('111111/1111', 'Ben', 'Cash', date '2009-01-01', 'M', 'Brno', 'Videnska, 4');
INSERT INTO Children (Id, FirstName, SecondName, Birthday, Sex, City, Address)
VALUES ('111001/1921', 'Jorge', 'Winston', date '2015-01-01', 'M', 'Brno', 'Videnska, 4');
INSERT INTO Children (Id, FirstName, SecondName, Birthday, Sex, City, Address)
VALUES ('100001/1900', 'Simona', 'Jelinek', date '2017-05-24', 'F', 'Slavkov u Brna', 'Kartouzska, 21');
INSERT INTO Children (Id, FirstName, SecondName, Birthday, Sex, City, Address)
VALUES ('100071/1909', 'Petra', 'Jelinek', date '2018-01-10', 'F', 'Slavkov u Brn0', 'Kartouzska, 21');

INSERT INTO ChildIsInClass (ChildId, ClassId, StartDate, EndData)
VALUES ('111111/1111', 1, date '2023-10-22', date '2024-06-30');
INSERT INTO ChildIsInClass (ChildId, ClassId, StartDate, EndData)
VALUES ('111001/1921', 1, date '2023-12-29', date '2024-09-20');
INSERT INTO ChildIsInClass (ChildId, ClassId, StartDate, EndData)
VALUES ('100001/1900', 2, date '2024-01-01', date '2024-12-31');
INSERT INTO ChildIsInClass (ChildId, ClassId, StartDate, EndData)
VALUES ('100001/1900', 1, date '2023-01-01', date '2023-12-31');
INSERT INTO ChildIsInClass (ChildId, ClassId, StartDate, EndData)
VALUES ('100071/1909', 2, date '2024-03-10', date '2025-07-20');

INSERT INTO Consents (ConsentId, ChildId, ParentId, SignatureDate, Activity, State)
VALUES (0, '111001/1921', '045500/0967', date '2024-03-18', 'Excursion', 'Approved');
INSERT INTO Consents (ConsentId, ChildId, ParentId, SignatureDate, Activity, State)
VALUES (1, '111111/1111', '045500/0967', date '2024-03-10', 'Excursion', 'Rejected');
INSERT INTO Consents (ConsentId, ChildId, ParentId, SignatureDate, Activity, State)
VALUES (1, '100001/1900', '349930/0465', date '2024-02-22', 'Charity event', 'Awaiting');
INSERT INTO Consents (ConsentId, ChildId, ParentId, SignatureDate, Activity, State)
VALUES (0, '100071/1909', '349930/0465', date '2024-02-10', 'Doctor visit', 'Rejected');

INSERT INTO ConsentRejections (ChildId, ConsentId, ParentId, SignatureDate)
VALUES ('111111/1111', 1, '045500/0967', date '2024-03-12');
INSERT INTO ConsentRejections (ChildId, ConsentId, ParentId, SignatureDate)
VALUES ('100071/1909', 0, '349930/0465', date '2024-02-12');

INSERT INTO Guidance (GuidanceId, ChildId, ParentId, TakingPersonId, SignatureDate, Activity, State)
VALUES (0, '111111/1111', '045500/0967', '999999/9967', date '2024-03-14', 'Doctor visit', 'Rejected');
INSERT INTO Guidance (GuidanceId, ChildId, ParentId, TakingPersonId, SignatureDate, Activity, State)
VALUES (0, '111001/1921', '045500/0967', '999999/9967', date '2024-03-19', 'Doctor visit', 'Approved');
INSERT INTO Guidance (GuidanceId, ChildId, ParentId, TakingPersonId, SignatureDate, Activity, State)
VALUES (0, '100071/1909', '349930/0465', '897789/9961', date '2024-01-12', 'Swimming', 'Rejected');
INSERT INTO Guidance (GuidanceId, ChildId, ParentId, TakingPersonId, SignatureDate, Activity, State)
VALUES (1, '100071/1909', '349930/0465', '999999/9967', date '2024-03-20', 'Skiing', 'Rejected');
INSERT INTO Guidance (GuidanceId, ChildId, ParentId, TakingPersonId, SignatureDate, Activity, State)
VALUES (2, '100071/1909', '349930/0465', '897789/9961', date '2024-03-21', 'Skiing', 'Approved');

INSERT INTO GuidanceRejections (ChildId, GuidanceId, ParentId, SignatureDate)
VALUES ('111111/1111', 0, '045500/0967', date '2024-03-14');
INSERT INTO GuidanceRejections (ChildId, GuidanceId, ParentId, SignatureDate)
VALUES ('100071/1909', 0, '349930/0465', date '2024-03-20');
INSERT INTO GuidanceRejections (ChildId, GuidanceId, ParentId, SignatureDate)
VALUES ('100071/1909', 1, '349930/0465', date '2024-01-15');


-- Find each child's consent activity
SELECT FIRSTNAME, SECONDNAME, ACTIVITY
FROM CHILDREN
         JOIN CONSENTS ON CHILDREN.ID = CONSENTS.CHILDID;

-- Find children that attend or attended class with the name Champion
SELECT FIRSTNAME, SECONDNAME, STARTDATE, ENDDATA
FROM CHILDREN
         JOIN CHILDISINCLASS ON CHILDREN.ID = CHILDISINCLASS.CHILDID
         JOIN CLASSES ON CHILDISINCLASS.CLASSID = CLASSES.ID
WHERE NAME = 'Champion';

-- Find position and working hours of Oskar Dolezal
SELECT POSITION, DAYOFWEEK, STARTTIME, ENDTIME
FROM ADULTS
         JOIN TEACHERS ON ADULTS.ID = TEACHERS.ID
         JOIN WORKSAS ON TEACHERS.ID = WORKSAS.TEACHERID
WHERE FIRSTNAME = 'Oskar'
  AND SECONDNAME = 'Dolezal';

-- Find guidance count for each child
SELECT FIRSTNAME, SECONDNAME, COUNT(*) AS Guidance_Count
FROM CHILDREN
         JOIN GUIDANCE ON CHILDREN.ID = GUIDANCE.CHILDID
GROUP BY FIRSTNAME, SECONDNAME;
-- Find children count that attend classes
SELECT ID, NAME, COUNT(CHILDID) AS Children_Count
FROM CLASSES
         LEFT JOIN CHILDISINCLASS ON CLASSES.ID = CHILDISINCLASS.CLASSID
GROUP BY ID, NAME
ORDER BY ID;

-- Find children without any guidance
SELECT FIRSTNAME, SECONDNAME
FROM CHILDREN
WHERE ID NOT IN (SELECT DISTINCT CHILDID FROM GUIDANCE);

-- Find classes without any teachers
SELECT NAME
FROM CLASSES C
WHERE NOT EXISTS(SELECT CLASSID FROM WORKSAS W WHERE C.ID = W.CLASSID);

-- 4 PART


-- Trigger 1: When a consent is rejected, log it
CREATE OR REPLACE TRIGGER Update_Consent_Status
    BEFORE UPDATE OF State ON Consents
    FOR EACH ROW
BEGIN
    IF :NEW.State = 'Rejected' THEN
        MERGE INTO ConsentRejections CR
        USING (SELECT 1 FROM DUAL) D
        ON (CR.ConsentId = :NEW.ConsentId)
        WHEN NOT MATCHED THEN
            INSERT (ChildId, ConsentId, ParentId, SignatureDate)
            VALUES (:NEW.ChildId, :NEW.ConsentId, :NEW.ParentId, SYSDATE);
    END IF;
END;

-- update for trigger
UPDATE Consents
SET State = 'Rejected'
WHERE ConsentId = 1;

-- Trigger 2: When a guidance is rejected, update the guidance state
CREATE OR REPLACE TRIGGER Log_Guidance_Rejection
    AFTER INSERT
    ON GuidanceRejections
    FOR EACH ROW
BEGIN
    UPDATE Guidance
    SET State = 'Rejected'
    WHERE ChildId = :NEW.ChildId
      AND GuidanceId = :NEW.GuidanceId;
END;
/

-- Saved procedure 1: Show all consents
CREATE OR REPLACE PROCEDURE Show_Consents
    IS
    CURSOR c1 IS
        SELECT ChildId, Activity, State
        FROM Consents;
BEGIN
    FOR rec IN c1
        LOOP
            DBMS_OUTPUT.PUT_LINE('Child ID: ' || rec.ChildId || ', Activity: ' || rec.Activity || ', State: ' ||
                                 rec.State);
        END LOOP;
END;
/

-- Saved procedure 2: Add a teacher
CREATE OR REPLACE PROCEDURE Add_Teacher(
    p_Id CHAR, p_FirstName VARCHAR, p_SecondName VARCHAR, p_Birthday DATE, p_Sex CHAR, p_Address VARCHAR,
    p_City VARCHAR, p_PhoneNumber CHAR, p_Email VARCHAR)
    IS
BEGIN
    INSERT INTO Adults (Id, FirstName, SecondName, Birthday, Sex, Address, City, PhoneNumber, Email)
    VALUES (p_Id, p_FirstName, p_SecondName, p_Birthday, p_Sex, p_Address, p_City, p_PhoneNumber, p_Email);
    INSERT INTO Teachers (Id)
    VALUES (p_Id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- index 1
CREATE INDEX idx_childid ON Consents (ChildId);

-- EXPLAIN PLAN for child
EXPLAIN PLAN FOR
SELECT *
FROM Consents
WHERE ChildId = '111001/1921';
SELECT *
FROM TABLE (DBMS_XPLAN.DISPLAY);

-- Grants for the second user
GRANT SELECT, UPDATE ON Classes TO XKOLIA00;
GRANT SELECT, UPDATE ON ADULTS TO XKOLIA00;
GRANT SELECT, UPDATE, DELETE ON Classes TO XKOLIA00;
GRANT SELECT, UPDATE ON ConsentRejections TO XKOLIA00;
GRANT SELECT, UPDATE, DELETE ON Consents TO XKOLIA00;
GRANT DELETE ON Guidance TO XKOLIA00;

-- Materialized view for approved consents
CREATE MATERIALIZED VIEW XKOLIA00.Consent_View
    REFRESH COMPLETE
AS
SELECT *
FROM Consents
WHERE State = 'Approved';

-- Demonstration of the materialized view
SELECT *
FROM XKOLIA00.Consent_View;

-- Saved procedure 3: Add multiple teachers
CREATE OR REPLACE PROCEDURE Add_Multiple_Teachers(p_Teachers SYS_REFCURSOR)
    IS
    v_Id          CHAR(11);
    v_FirstName   VARCHAR(20);
    v_SecondName  VARCHAR(20);
    v_Birthday    DATE;
    v_Sex         CHAR(1);
    v_Address     VARCHAR(50);
    v_City        VARCHAR(30);
    v_PhoneNumber CHAR(20);
    v_Email       VARCHAR(20);
BEGIN
    LOOP
        FETCH p_Teachers INTO v_Id, v_FirstName, v_SecondName, v_Birthday, v_Sex, v_Address, v_City, v_PhoneNumber, v_Email;
        EXIT WHEN p_Teachers%NOTFOUND;

        INSERT INTO Adults (Id, FirstName, SecondName, Birthday, Sex, Address, City, PhoneNumber, Email)
        VALUES (v_Id, v_FirstName, v_SecondName, v_Birthday, v_Sex, v_Address, v_City, v_PhoneNumber, v_Email);
        INSERT INTO Teachers (Id)
        VALUES (v_Id);
    END LOOP;
END;
/


-- Indexes on ID columns for faster JOIN operations
CREATE INDEX idx_Adults_City ON Adults (City);
CREATE INDEX idx_WorksAs_TeacherId ON WorksAs (TeacherId, ClassId);
CREATE INDEX idx_WorksAs_ClassId ON WorksAs (ClassId);

-- EXPLAIN PLAN for a more complex query
EXPLAIN PLAN FOR
SELECT a.FirstName, a.SecondName, c.Name, c.Classroom
FROM Adults a
         JOIN Teachers t ON a.Id = t.Id
         JOIN WorksAs w ON t.Id = w.TeacherId
         JOIN Classes c ON w.ClassId = c.Id
WHERE a.City = 'Brno';

SELECT *
FROM TABLE (DBMS_XPLAN.DISPLAY);

-- Materialized view for performance monitoring
CREATE MATERIALIZED VIEW Performance_Monitoring
    REFRESH COMPLETE
AS
SELECT t.Id,
       a.FirstName,
       a.SecondName,
       COUNT(*)                                               AS Classes_Count,
       AVG(EXTRACT(HOUR FROM (w.EndTime - w.StartTime)) + EXTRACT(MINUTE FROM (w.EndTime - w.StartTime)) /
                                                          60) AS Average_Working_Hours
FROM Teachers t
         JOIN Adults a ON t.Id = a.Id
         JOIN WorksAs w ON t.Id = w.TeacherId
GROUP BY t.Id, a.FirstName, a.SecondName;

-- Demonstration of the materialized view
SELECT *
FROM Performance_Monitoring;
