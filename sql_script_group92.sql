--1.1
--Παρουσίαση κωδικού μαθήματος, τίτλου μαθήματος και ονοματεπωνύμων διδασκόντων
--καθηγητών (διαχωρισμένα με κόμμα) για όλα τα εξαμηνιαία μαθήματα του τρέχοντος 
--εξαμήνου.
CREATE OR REPLACE VIEW course_and_prof AS
SELECT c.course_code, c.course_title, pe.name || ', ' || pe.surname AS professor_name
FROM "CourseRun" cr 
JOIN "Semester" s ON cr.semesterrunsin = s.semester_id 
JOIN "Course" c ON c.course_code = cr.course_code 
JOIN "Teaches" t ON t.course_code = c.course_code 
JOIN "Professor" p ON t.amka = p.amka 
JOIN "Person" pe ON p.amka = pe.amka
WHERE s.semester_status = 'present';



--2.1
CREATE OR REPLACE FUNCTION create_professor(num integer)
RETURNS void AS $$ 
DECLARE 
	amka1 character varying;
	code1 integer;
	rank1 rank_type;
BEGIN 
	FOR i IN 1..num LOOP 
		SELECT create_person() INTO amka1;
		SELECT random_code() INTO code1; 
		SELECT random_rank() INTO rank1; 

		--insert/create a "Professor"
		INSERT INTO "Professor" (amka , labjoins, rank) VALUES (amka1, code1, rank1); 
	END LOOP;
END; 
$$
LANGUAGE 'plpgsql' VOLATILE;	


------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_labTeacher(num integer)
RETURNS void AS $$ 
DECLARE 
	amka1 character varying;
	labworks1 integer; 
	level1 level_type; 
BEGIN 
	FOR i IN 1..num LOOP 
		SELECT create_person() INTO amka1;
		SELECT random_code() INTO labworks1; 
		SELECT random_level() INTO level1; 

		--insert/create a "Professor"
		INSERT INTO "LabTeacher" (amka , labworks, level) VALUES (amka1, labworks1, level1); 
	END LOOP;
END; 
$$
LANGUAGE 'plpgsql' VOLATILE;	

------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_student(num integer)
RETURNS void AS $$ 

DECLARE
	X character(1);
	amka1 character varying; 
	am1 character(10);
	en_date date;
	year character (4); 
	AAAAA character(5); 
BEGIN 
	FOR i IN 1..$1 LOOP 
		SELECT create_person() INTO amka1;
		SELECT random_date() INTO en_date;
		SELECT trim_year(en_date) INTO year;
		SELECT random_X() INTO X; 
		SELECT append_random(en_date) INTO AAAAA; 
		SELECT generate_am(year,X,AAAAA) INTO am1; 		
		
		--insert/create a "Student"
		INSERT INTO "Student" (amka , am, entry_date) VALUES (amka1, am1, en_date); 
	END LOOP;
END; 
$$
LANGUAGE 'plpgsql' VOLATILE;

------------------------------------------------------------------------------------
--this function appends random and unique "AAAAA" for every am.
--(note that this number increases by 1 for students of the same entry year)
CREATE OR REPLACE FUNCTION append_random(en_date date)
RETURNS character(5) AS $$
DECLARE
  maxID integer :=0;
  result character(5) ; 
BEGIN

	SELECT MAX(RIGHT(s.am, 5)::integer)::integer INTO maxID FROM "Student" s
	WHERE trim_year(s.entry_date)= trim_year($1);

	 IF maxID IS NULL THEN 
	 	result :=lpad(0::text, 5, '0'); 
        RETURN result;
     END IF;

     result :=lpad((maxID+1)::text, 5, '0'); 
     RETURN result;
END;
$$ LANGUAGE plpgsql;
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trim_year(en_date date)
RETURNS character(4) AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM en_date)::character(4);
END;
$$ LANGUAGE plpgsql VOLATILE;


------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION random_date()
RETURNS date AS $$
DECLARE
  start_date CONSTANT date := '1970-01-01';
  end_date CONSTANT date := '2050-12-31';
  random_days integer;
BEGIN
  SELECT (random() * (end_date - start_date + 1))::integer INTO random_days;
  RETURN start_date + random_days;
END;
$$ LANGUAGE plpgsql;


------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.random_fathernames()
RETURNS character varying   
AS $$
 
DECLARE
	fname character varying;
BEGIN
    
     SELECT nam.name FROM "Name" nam WHERE nam.sex='M' ORDER BY random()
 	INTO fname;
 	return fname;
END; 
$$ 
LANGUAGE plpgsql VOLATILE;



------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION random_X()
RETURNS character(1) AS $$
DECLARE
    bit character(1);
BEGIN
    IF random() < 0.5 THEN
        bit := '0';
    ELSE
        bit := '1';
    END IF;
    RETURN bit;
END;
$$ LANGUAGE plpgsql VOLATILE;

------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION random_code()
RETURNS integer AS
$$
BEGIN
	RETURN  lab_code
	FROM "Lab"
	ORDER BY random()
	LIMIT 1;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;


------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_am(year1 character(4), X character(1), num character(5))
RETURNS character(10) AS $$
DECLARE
    result character(10);
BEGIN
    result := year1 || X || num;
    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION random_rank()
RETURNS rank_type AS
$$
DECLARE 
    rand_rank rank_type;
BEGIN
	SELECT (ARRAY['full', 'associate', 'assistant', 'lecturer'])[floor(random()*4)+1] INTO rand_rank; 
	RETURN rand_rank;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;


------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION random_level()
RETURNS level_type AS
$$
DECLARE 
    lvl level_type;
BEGIN
	SELECT (ARRAY['A', 'B', 'C', 'D'])[floor(random()*4)+1] INTO lvl; 
	RETURN lvl;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;


------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION random_between(min INTEGER, max INTEGER)
RETURNS INTEGER AS $$
BEGIN
  RETURN FLOOR(RANDOM() * (max - min + 1)) + min;
END;
$$ LANGUAGE plpgsql;


------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_person()
RETURNS character varying
AS $$
DECLARE 
	amka1 character varying;  
	name1 character varying(30);
	father_name1 character varying(30);
	surename1 character varying(30);
	sex character(1); 
	email1  character varying(30);
BEGIN
	SELECT random_amka() INTO amka1; 
	SELECT n.name, n.sex INTO name1, sex FROM random_names(1) n; 
	SELECT random_fathernames() INTO father_name1;
    SELECT adapt_surname(s.surname,sex) INTO surename1 FROM random_surnames(1) s ;
	SELECT make_latin(surename1) || '@tuc.gr' INTO email1;     
	
	INSERT INTO "Person" (amka, name, father_name, surname, email)
    VALUES (
        amka1,
        name1,
        father_name1,
        surename1,
        email1
    );
  
   RETURN amka1;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION random_amka()
RETURNS character varying
AS $$
BEGIN
    RETURN generate_random_11_digit_integer()::character varying;
END;
$$ LANGUAGE plpgsql;


---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_random_11_digit_integer()
RETURNS bigint
AS $$
DECLARE
    random_number bigint;
BEGIN
    random_number := trunc(random() * 9000000000 + 1000000000)::bigint;
    RETURN random_number;
END;
$$ LANGUAGE plpgsql;


-------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION random_surnames(n integer)
RETURNS TABLE(surname character varying(30))
AS $$

BEGIN
RETURN QUERY 
	SELECT snam.surname 
	FROM (SELECT "Surname".surname
		  FROM "Surname"
	      WHERE right("Surname".surname,2)='ΗΣ'
		  ORDER BY random() LIMIT n) as snam ; --generates random numbers, one for each row, and then sorts by them. So it results in n rows being presented in a random order
	
END;
$$
LANGUAGE 'plpgsql' VOLATILE; --VOLATILE such as functions involving random() and CURRENT_TIMESTAMP that can be expected to change output even in the same query call.


-------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION random_fathernames(n integer)
RETURNS character varying(30)
AS $$
DECLARE 
	result_name character varying(30); 
BEGIN

	SELECT nam.name
	FROM (SELECT "Name".name, "Name".sex
		  FROM "Name" WHERE "Name".sex = 'M'
		  ORDER BY random() LIMIT n) as nam INTO result_name;
    RETURN result_name;
END;
$$
LANGUAGE 'plpgsql' VOLATILE; --VOLATILE such as functions involving random() and CURRENT_TIMESTAMP that can be expected to change output even in the same query call.


-------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.make_latin(greek_text text)
RETURNS text
AS $$
DECLARE
  latin_text TEXT := '';
BEGIN
  SELECT
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE
		(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE
		(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE
		(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    greek_text,
    'Α', 'a'),
    'Β', 'b'),
    'Γ', 'g'),
    'Δ', 'd'),
    'Ε', 'e'),
    'Ζ', 'z'),
    'Η', 'i'),
    'Θ', 'th'),
    'Ι', 'i'),
    'Κ', 'k'),
    'Λ', 'l'),
    'Μ', 'm'),
    'Ν', 'n'),
    'Ξ', 'x'),
    'Ο', 'o'),
    'Π', 'p'),
    'Ρ', 'r'),
    'Σ', 's'),
    'Τ', 't'),
    'Υ', 'y'),
    'Φ', 'ph'),
    'Χ', 'ch'),
    'Ψ', 'ps'),
    'Ω', 'o'
  INTO latin_text;
  RETURN latin_text;
END;
$$ LANGUAGE 'plpgsql';


-------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION random_names(n integer)
RETURNS TABLE(name character varying(30),sex character(1)) 
AS $$ 
BEGIN
	RETURN QUERY 
	SELECT nam.name, nam.sex
	FROM (SELECT "Name".name, "Name".sex
		  FROM "Name"
		  ORDER BY random() LIMIT n) as nam;
	
END;
$$
LANGUAGE 'plpgsql' VOLATILE; --VOLATILE such as functions involving random() and CURRENT_TIMESTAMP that can be expected to change output even in the same query call.

------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.adapt_surname(surname character varying, sex character)
RETURNS character varying
AS $$
DECLARE
	result character varying;
BEGIN
	result = surname;
	IF right(surname,2)<>'ΗΣ' THEN
		RAISE NOTICE 'Cannot handle this surname';
		ELSIF sex='F' THEN
			result = left(surname,-1);
			ELSIF sex<>'M' THEN
				RAISE NOTICE 'Wrong sex parameter';
	END IF;
	RETURN result;
END;
$$LANGUAGE 'plpgsql';


-------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_am(year integer, num integer)
RETURNS character(10) AS
$$
BEGIN
	RETURN concat(year::character(4),lpad(num::text,6,'0')); --cast(expression as target_type) or ::. LPAD() function returns a string left-padded to length characters.
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;--IMMUTABLE meaning that the output of the function can be expected to be the same if the inputs are the same.


-------------------------------------------------------------------------------------
--Εισαγωγή βαθμολογίας για εγγεγραμμένους φοιτητές σε μαθήματα συγκεκριμένου εξαμήνου 
--το οποίο δίνεται ως παράμετρος. Θα εισάγεται ένας τυχαίος ακέραιος αριθμός από το 1 έως 
--και το 10 ως βαθμός γραπτής εξέτασης. Ομοίως για τα εργαστηριακά μαθήματα θα εισάγεται 
--ένα τυχαίος αριθμός από το 1 ως το 10 ως βαθμός εργαστηρίου. Αν υπάρχουν ήδη βαθμολογίες 
--για κάποιους φοιτητές, δεν γίνεται ενημέρωση για αυτές

-- This function will update the exam and lab grades for all rows in the Register table
-- where exam_grade and lab_grade are both 0 and where the course_code and serial_number
-- match a row in the subquery that finds the courses for a given semester.
CREATE OR REPLACE FUNCTION insert_grade(semester_id integer)
RETURNS void AS
$$
BEGIN
	UPDATE "Register" r 
	SET exam_grade = random_grade(), lab_grade = random_grade() 
	FROM (
		SELECT cr.course_code, cr.serial_number 
		FROM "CourseRun" cr
		WHERE cr.semesterrunsin = semester_id
	) AS t
	WHERE r.course_code = t.course_code 
		AND r.serial_number = t.serial_number
		AND r.exam_grade = 0 
		AND r.lab_grade = 0;
		
	--now AFTER THE UPDATE, do the following update for the final grade. 	
	--(in order to calculate the final grade, lab and exam grades should be updated and not "empty")
	UPDATE "Register" r 	
	SET final_grade = calculate_final_grade(r.exam_grade, r.lab_grade)
	FROM (
		SELECT cr.course_code, cr.serial_number 
		FROM "CourseRun" cr
		WHERE cr.semesterrunsin = semester_id
	) AS t
	WHERE r.course_code = t.course_code 
		AND r.serial_number = t.serial_number;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
-------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_final_grade(exam numeric , lab numeric)
RETURNS numeric AS $$ 
DECLARE 
	exam_perc numeric; 
	lab_min numeric; 
	exam_min numeric; 
	result numeric; 	
BEGIN 
	SELECT cr.exam_percentage, cr.exam_min, cr.lab_min INTO exam_perc , exam_min , lab_min 
	FROM "CourseRun" cr 
	JOIN "Register" r ON cr.course_code = r.course_code 
	WHERE r.exam_grade=$1 AND r.lab_grade=$2;
	 
	IF exam_perc = 100 THEN --course is completely theoretical 
		result = $1; 
	ELSE --course contains a lab 
		IF $1 < exam_min THEN --set final grade = exam grade
			result = $1; 
		ELSEIF $2 < lab_min THEN 
			result = 0;
		END IF; 	
	END IF; 
		result = $1*(exam_perc)/100 + $2*(100-exam_perc)/100;
	RETURN ROUND(result); 
END; 
$$ LANGUAGE plpgsql;
-------------------------------------------------------
CREATE OR REPLACE FUNCTION random_grade()
RETURNS numeric AS $$
DECLARE
   random_num numeric;
BEGIN
   -- Generate a random number between 0 and 1, and scale it to 0-10
   random_num := ROUND(random()::numeric * 10, 2);
   RETURN random_num;
END;
$$ LANGUAGE plpgsql;

--3.1
--Αναζήτηση προσωπικών στοιχείων φοιτητών με βάση τον αριθμό μητρώου
CREATE OR REPLACE FUNCTION student_data(am character(10))
RETURNS "Person" AS $$
DECLARE 
	result_p "Person"; 
BEGIN
    
	SELECT * INTO result_p FROM "Person" pe
	WHERE pe.amka IN (SELECT s.amka
					  FROM "Student" s
					  WHERE s.am = $1); 
	RAISE NOTICE 'Student data are, % ,%, % ,% ,% ' ,result_p.amka , 
	result_p.name, result_p.father_name, result_p.surname , result_p.email;
	
	RETURN result_p;
END;
$$
LANGUAGE 'plpgsql' VOLATILE; --VOLATILE such as functions involving random() and 


---------------------------------------------------------------------------------------------
--3.2 
--Ανάκτηση ονοματεπωνύμου και αριθμού μητρώου για τους φοιτητές που παρακολουθούν ένα 
--συγκεκριμένο μάθημα του τρέχοντος εξαμήνου για το οποίο δίνεται ο κωδικός του

DROP FUNCTION IF EXISTS public.fullnames_am(integer);
CREATE OR REPLACE FUNCTION fullnames_am(code character(7))
RETURNS TABLE (name character varying(30), surname character varying(30), am character(10)) AS $$
BEGIN
    RETURN QUERY
	SELECT p.name, p.surname, s.am 
	FROM "Person" p
	INNER JOIN "Student" s ON p.amka=s.amka
	INNER JOIN "Register" r ON r.amka = s.amka 
	WHERE r.course_code = code; 

END;
$$
LANGUAGE 'plpgsql'; 

--SELECT fullnames_am('ΑΓΓ 101');
----------------------------------------------------------------------

--3.3  
--Aνάκτηση του ονοματεπωνύμου όλων των προσώπων και χαρακτηρισμό τους (καθηγητές ή 
--εργαστηριακό προσωπικό ή φοιτητές). Το αποτέλεσμα είναι πλειάδες της μορφής: επώνυμο, 
--όνομα, χαρακτηρισμός.
CREATE OR REPLACE FUNCTION get_person_property()
RETURNS TABLE (name character varying(30), surname character varying(30), property text) AS $$
BEGIN
    RETURN QUERY
        SELECT p.name, p.surname, 'Student' AS property
        FROM "Person" p JOIN "Student" s ON p.amka = s.amka
       	UNION
        SELECT p.name, p.surname, 'Professor' AS property
        FROM "Person" p JOIN "Professor" pr ON p.amka = pr.amka
        UNION
        SELECT p.name, p.surname, 'Lab Teacher' AS property
        FROM "Person" p JOIN "LabTeacher" lt ON p.amka = lt.amka;
END;
$$ LANGUAGE plpgsql;

SELECT get_person_property();
----------------------------------------------------------------------

--3.4
--Ανάκτηση των υποχρεωτικών μαθημάτων που δεν έχει ακόμη παρακολουθήσει επιτυχώς ένας 
--συγκεκριμένος φοιτητής για να μπορέσει να αποφοιτήσει από ένα συγκεκριμένο πρόγραμμα 
--σπουδών. Ο κωδικός του προγράμματος θα δίνεται ως όρισμα.

CREATE OR REPLACE FUNCTION func_34(ProgramID integer, amka character varying)
RETURNS TABLE(course_code character(7) , course_title character(100) , units smallint) AS $$
BEGIN
    RETURN QUERY 
	SELECT c.course_code, c.course_title, c.units 
	FROM "Course" c JOIN "ProgramOffersCourse" o ON  c.course_code = o.CourseCode
	JOIN "Register" r ON  r.course_code = o.CourseCode
	WHERE o.ProgramID = $1 AND c.obligatory = TRUE AND r.final_grade < 5 AND r.amka = $2; 
	
	
	
	DROP TABLE temp_1;
	
END;
$$ LANGUAGE plpgsql;

--SELECT func_31() cant check it yet... 


--4.1..1. κατά την εισαγωγή νέου μελλοντικού εξαμήνου (κατάσταση «future») θα γίνεται 
--έλεγχος ορθότητας με βάση τις ημερομηνίες έναρξης και λήξης έτσι ώστε να μην 
--επικαλύπτεται με κανένα άλλο καταχωρημένο εξάμηνο και να ακολουθεί χρονικά το 
--τρέχον εξάμηνο.


CREATE OR REPLACE FUNCTION check_future_semester() RETURNS TRIGGER AS $$
DECLARE
   current_semester "Semester"%ROWTYPE;
BEGIN
    SELECT * INTO current_semester FROM "Semester" WHERE semester_status = 'present';
   
    IF (NEW.semester_status = 'future' AND EXISTS (SELECT 1 FROM "Semester"
        WHERE current_semester.semester_status <> 'future' AND (
        (NEW.start_date <= current_semester.end_date AND NEW.end_date >= current_semester.start_date)
        OR (NEW.start_date <= current_semester.start_date AND NEW.end_date >= current_semester.start_date)))
    ) THEN
        RAISE EXCEPTION 'New semester overlaps with existing semesters';
        RETURN OLD; 
    ELSIF NEW.semester_status = 'future' AND (
        current_semester.end_date >= NEW.start_date OR current_semester.semester_status IS NULL
    ) THEN
        RAISE EXCEPTION 'New semester does not follow current semester in time';
        RETURN OLD; 
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
												  
												  
CREATE TRIGGER tr_411 
BEFORE INSERT ON "Semester"
FOR EACH ROW 
WHEN (NEW.semester_status ='future')
EXECUTE FUNCTION check_future_semester();

---------------------------------------------------------------------------------------------------
--4.1..2. κατά την μεταβολή ενός μελλοντικού εξαμήνου σε τρέχον (ενημέρωση από future σε 
--present) θα γίνεται αυτόματη ενημέρωση του προηγούμενου τρέχοντος σε κατάσταση 
--«past». Θα λαμβάνουν χώρα όλοι οι απαιτούμενοι έλεγχοι συνέπειας ως προς τις 
--ημερομηνίες έναρξης και λήξης εξαμήνων έτσι ώστε να υπάρχει σωστή χρονική 
--ακολουθία.

CREATE OR REPLACE FUNCTION update_present_semester() RETURNS TRIGGER AS $$
DECLARE
    current_semester "Semester"%ROWTYPE;
BEGIN
    SELECT * INTO current_semester FROM "Semester" WHERE semester_status = 'present';
    IF OLD.semester_status = 'future' AND NEW.semester_status = 'present' AND EXISTS (
        SELECT 1 FROM "Semester"
        WHERE semester_status <> 'future' AND (
            (NEW.start_date <= end_date AND NEW.end_date >= start_date)
            OR (NEW.start_date <= start_date AND NEW.end_date >= start_date)
        )
    ) THEN
        RAISE EXCEPTION 'New semester overlaps with existing semesters';
		RETURN OLD; 
    ELSIF OLD.semester_status = 'future' AND NEW.semester_status = 'present' AND (
        current_semester.end_date >= NEW.start_date OR current_semester.semester_status IS NULL
    ) THEN
        RAISE EXCEPTION 'New semester does not follow current semester in time';
		RETURN OLD;
    ELSE
		RAISE NOTICE 'Update completed with no errors';
        UPDATE "Semester" SET semester_status = 'past' WHERE semester_id < OLD.semester_id AND semester_status = 'present';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 

CREATE TRIGGER tr_412 
BEFORE UPDATE ON "Semester"
FOR EACH ROW 
WHEN (OLD.semester_status = 'future' AND NEW.semester_status ='present') --εδω φαινεται η μεταβολη future->σε present
EXECUTE FUNCTION update_present_semester();
--------------------------------------------------------------------------------------------------------------


DROP TYPE IF EXISTS public.program_type CASCADE;

-- new type for handling types of programs
CREATE TYPE public.program_type AS ENUM (
    'typical',
    'foreign_language',
    'seasonal'
);




/* HELPFUL FUNCTIONS */




-- 1)
-- programs are grouped by thousands, e.g. 3002 is seasonal,
-- 1015 is typical, 2983 is foreign language program
-- ofc this means that max #programs are 999 per type
--
-- returns program_type (enum) given the ProgramID
-- returns null for an non-existent ProgramID
CREATE OR REPLACE FUNCTION type_of_program(progr_id INTEGER) RETURNS program_type AS 
$$
DECLARE
	max_programs_per_type CONSTANT INTEGER := 999;
BEGIN
	CASE progr_id / (max_programs_per_type + 1)
		WHEN 1 THEN
			RETURN 'typical';
		WHEN 2 THEN
			RETURN 'foreign_language';
		WHEN 3 THEN
			RETURN 'seasonal';
		ELSE
			RETURN NULL;
	END CASE;
END;
$$ LANGUAGE 'plpgsql';



-- 2)
-- returns weight given the units of a course
-- returns null for illegal units
CREATE OR REPLACE FUNCTION course_weight(units SMALLINT, OUT weight NUMERIC) AS
$$
BEGIN
	CASE
		WHEN units BETWEEN 1 AND 2 THEN
			weight := 1;
		WHEN units BETWEEN 3 AND 4 THEN
			weight := 1.5;
		WHEN units = 5 THEN
			weight := 2;
		ELSE
			weight := NULL;
	END CASE;
END;
$$ LANGUAGE 'plpgsql';



-- 3)
-- 2.4 helpful function
-- υλοποιήσετε μια συνάρτηση για την εισαγωγή ενοτήτων που θα δέχεται ως ορίσματα
-- τον κωδικό προγράμματος, τον κωδικό ενότητας και μια λίστα από κωδικούς μαθημάτων.
CREATE OR REPLACE FUNCTION insert_cust_units(seasonal_pr_id INTEGER, unit_code INTEGER,
	VARIADIC course_codes CHARACTER(7)[])
RETURNS VOID AS 
$$
BEGIN
	INSERT INTO "CustomUnits" ("CustomUnitID", "SeasonalProgramID", "Credits")
	SELECT unit_code, seasonal_pr_id, SUM(course.units)
	FROM "Course" course
	WHERE course.course_code = ANY(course_codes);

	INSERT INTO "RefersTo" ("CustomUnitID", "SeasonalProgramID", "CourseRunCode", "CourseRunSerial")
	SELECT unit_code, seasonal_pr_id, crun.course_code, crun.serial_number
	FROM "CourseRun" crun
		JOIN "Semester" semester ON (crun.semesterrunsin = semester.semester_id)
	WHERE crun.course_code = ANY(course_codes)
		AND semester.semester_status = 'present';
END;
$$ LANGUAGE 'plpgsql';




-- 4)
/*
	a function that takes as input a student and the program that we are interested
	in finding out whether the student can graduate from

	only works for typical and foreign language programs, that share the same grad 
	requirements

	returns null if the student cannot graduate and the diploma grade if they can
*/
CREATE OR REPLACE FUNCTION check_student_grad(st_am CHARACTER(10), progr_id INTEGER,
	OUT fin_grade NUMERIC)
AS
$$
DECLARE
	obl_thesis BOOLEAN; -- program has obl thesis
	thesis_grade NUMERIC; -- thesis grade
	-- thesis and courses weights in the diploma grade
	thesis_weight NUMERIC;
	courses_weight NUMERIC;
	-- min courses and credits requirements
	min_courses INTEGER;
	min_credits INTEGER;
	-- final_grade = grade_nom / grade_denom
	grade_nom NUMERIC := 0.0;
	grade_denom NUMERIC := 0.0;
	-- hold temp records and values, helpful when
	-- calculating final diploma grade
	temp_record RECORD;
	temp_sum_credits INTEGER := 0;
	temp_sum_courses INTEGER := 0;
	-- a cursor for all passed courses for a particular student and particular program
	-- ordered by: first obligatory then non and within this filter
	-- we order by grade (this will be helping when choosing which
	-- non obl grades to keep for the diploma [if we get to pick some])
	curs1 CURSOR FOR ( --final_grade, credits, obligatory 
		SELECT registry.final_grade AS grade,
			course.units AS credits,
			course.obligatory AS obl
		FROM "Register" registry
			JOIN "Student" student USING (amka)
			JOIN "Course" course USING (course_code)
			JOIN "ProgramOffersCourse" program ON (program."CourseCode" = registry.course_code)
		WHERE student.am = st_am
			AND program."ProgramID" = progr_id
			AND registry.register_status = 'pass'
		ORDER BY course.obligatory DESC,
			registry.final_grade DESC
	);
BEGIN
	-- cannot take diploma if obl thesis is not done
	-- if it's not obl then set grade to zero (don't care)
	-- also set weights respectively
	IF obl_thesis THEN
		-- find thesis grade
		SELECT "Grade" INTO thesis_grade
		FROM "Thesis" JOIN "Student" ON (amka = "StudentAMKA")
		WHERE "ProgramID" = progr_id AND am = st_am;

		IF (thesis_grade IS NULL OR thesis_grade < 5) THEN
			fin_grade = NULL;
			RETURN;
		ELSE
			thesis_weight := 0.2;
			courses_weight := 0.8;
		END IF;
	ELSE
		thesis_weight := 0;
		courses_weight := 1;

		thesis_grade := 0;
	END IF;

	-- PASS all obl courses
	-- effectively, what this query does is
	-- obl_courses MINUS passed_courses (as query results)
	-- if the resulting table is not empty of tuples
	-- the student cannot graduate
	IF EXISTS (
		SELECT course.course_code
		FROM "ProgramOffersCourse" offers
			JOIN "Course" course ON (course.course_code = offers."CourseCode")
		WHERE course.obligatory AND offers."ProgramID" = progr_id

		EXCEPT

		SELECT registry.course_code
		FROM "Register" registry
			JOIN "Student" student USING (amka)
		WHERE registry.register_status = 'pass' AND student.am = st_am	
	)
	THEN
		fin_grade = NULL;
		RETURN;
	END IF;

	-- find min courses and credits for this program
	SELECT "MinCourses" INTO min_courses FROM "Program" WHERE "ProgramID" = progr_id;
	SELECT "MinCredits" INTO min_credits FROM "Program" WHERE "ProgramID" = progr_id;
	/*
		"Για τον υπολογισμό του μέσου όρου των βαθμών των μαθημάτων, ο βαθμός κάθε μαθήματος
		πολλαπλασιάζεται με το συντελεστή βαρύτητας του μαθήματος και το άθροισμα των επιμέρους
		γινομένων διαιρείται με το άθροισμα των συντελεστών βαρύτητας όλων των μαθημάτων."
		
		so, the final_grade is the weighted avg of the passed courses
		
			Σ(course_grade*course_weight) / Σ(course_weight)
	*/

	-- with this LOOP we achieve taking the student's obligatory courses
	-- into account but also taking the best grades from the non
	-- obligatory ones until we achieve the min credits
	OPEN curs1;
	LOOP
		FETCH curs1 INTO temp_record;
		-- if we have reached the min credits then exit
		EXIT WHEN NOT FOUND OR temp_sum_credits >= min_credits;

		temp_sum_credits := temp_sum_credits + temp_record.credits;
		temp_sum_courses := temp_sum_courses + 1;

		grade_nom 	:= grade_nom + course_weight(temp_record.credits)*temp_record.grade;
		grade_denom := grade_denom + course_weight(temp_record.credits);
	END LOOP;
	CLOSE curs1;

	-- calculate diploma grade which will be the output of the function
	IF (temp_sum_credits >= min_credits AND temp_sum_courses >= min_courses AND grade_denom <> 0) THEN
		fin_grade := thesis_weight*thesis_grade + courses_weight*(grade_nom/grade_denom);
	ELSE
		fin_grade = NULL;
	END IF;
END;
$$ LANGUAGE 'plpgsql';






-- 5)
/*
	a function that takes as input a student and the program that we are interested
	in finding out whether the student can graduate from

	only works for seasonal programs

	returns null if the student cannot graduate and the certificate grade if they can
*/
CREATE OR REPLACE FUNCTION check_student_certificate(st_am CHARACTER(10), progr_id INTEGER,
	OUT fin_grade NUMERIC)
AS
$$
DECLARE
	obl_thesis BOOLEAN; -- program has obl thesis
	thesis_grade NUMERIC; -- thesis grade
	-- thesis and courses weights in the diploma grade
	thesis_weight NUMERIC;
	courses_weight NUMERIC;
	-- min courses and credits requirements
	min_courses INTEGER;
	min_credits INTEGER;
	-- final_grade = grade_nom / grade_denom
	grade_nom NUMERIC := 0.0;
	grade_denom NUMERIC := 0.0;
	-- hold temp records helpful when
	-- calculating final diploma grade
	temp_record RECORD;
	-- a cursor for all courses for a particular
	-- student and a particular seasonal program
	curs1 CURSOR FOR (
		SELECT registry.final_grade AS grade,
			registry.register_status AS status
		FROM "RefersTo" refers
			JOIN "Register" registry ON (registry.course_code = refers."CourseRunCode"
				AND registry.serial_number = refers."CourseRunSerial")
			JOIN "Student" student USING (amka)
		WHERE student.am = st_am
			AND refers."SeasonalProgramID" = progr_id
	);
BEGIN
	-- check if program has obligatory thesis (project)
	SELECT "Obligatory" INTO obl_thesis FROM "Program" WHERE "ProgramID" = progr_id;
	
	-- cannot take certificate if obl thesis is not done
	-- if it's not obl then set grade to zero (don't care)
	-- also set weights respectively
	IF obl_thesis THEN
		-- find thesis grade
		SELECT "Grade" INTO thesis_grade
		FROM "Thesis"
			JOIN "Student" ON (st.amka = "StudentAMKA")
		WHERE "ProgramID" = progr_id
			AND am = st_am;

		IF (thesis_grade IS NULL OR thesis_grade < 5) THEN
			fin_grade = NULL;
			RETURN;
		ELSE
			thesis_weight := 0.2;
			courses_weight := 0.8;
		END IF;
	ELSE 
		thesis_weight := 0;
		courses_weight := 1;

		thesis_grade := 0;
	END IF;

	-- PASS for all courses of seasonal program
	OPEN curs1;
	LOOP
		FETCH curs1 INTO temp_record;
		EXIT WHEN NOT FOUND;

		IF (temp_record.status = 'fail') THEN
			fin_grade := NULL;
			RETURN;
		END IF;

		grade_nom := grade_nom + temp_record.grade;
		grade_denom := grade_denom + 1;
	END LOOP;
	CLOSE curs1;
	

	-- calculate diploma grade which will be the output of the function
	IF (grade_denom <> 0) THEN
		fin_grade := thesis_weight*thesis_grade + courses_weight*(grade_nom/grade_denom);
	ELSE
		fin_grade = NULL;
	END IF;
END;
$$ LANGUAGE 'plpgsql';




-- 6)
/*
	Η τελική βαθμολογία ενός μαθήματος διαμορφώνεται ως εξής:
		1. Αν το μάθημα δεν είναι εργαστηριακό, η τελική βαθμολογία είναι ίση με το βαθμό γραπτής
		εξέτασης καθώς ο βαθμός υπολογίζεται με συμμετοχή 100% όπως ήδη αναφέρθηκε.

		2. Αν το μάθημα είναι εργαστηριακό και ο βαθμός εργαστηρίου είναι αυστηρά μικρότερος από
		το σχετικό ελάχιστο όριο, τότε τίθεται αυτομάτως ως βαθμός τελικής βαθμολογίας το μηδέν
		(0) ακόμη και αν ζητείται η ενημέρωση σε μη μηδενική τιμή.

		3. Αν το μάθημα είναι εργαστηριακό και ο βαθμός γραπτής εξέτασης είναι αυστηρά μικρότερος
		από το σχετικό ελάχιστο όριο, τότε η τελική βαθμολογία είναι ο βαθμός της γραπτής εξέτασης
		(δεν λαμβάνεται υπόψη ο βαθμός εργαστηρίου).

		4. Σε κάθε άλλη περίπτωση εφαρμόζεται το ποσοστό συμμετοχής της γραπτής εξέτασης για να
		συνδυαστούν οι βαθμοί εργαστηρίου και γραπτής στην εξαγωγή της τελικής βαθμολογίας.

	Για να θεωρηθεί επιτυχής η παρακολούθηση ενός μαθήματος και να κατοχυρωθεί για έναν φοιτητή, θα
	πρέπει αυτός να έχει τελική βαθμολογία μεγαλύτερη ή ίση του πέντε (5).
*/
CREATE OR REPLACE FUNCTION calculate_grade(st_amka VARCHAR, course_code CHARACTER(7),
	serial_num INTEGER, OUT fin_grade NUMERIC)
AS
$$
BEGIN
	SELECT (CASE
				WHEN crun.exam_percentage = 100 THEN
					reg.exam_grade
				WHEN crun.exam_percentage <> 100 AND reg.lab_grade < crun.lab_min THEN
					0
				WHEN crun.exam_percentage <> 100 AND reg.exam_grade < crun.exam_min THEN
					reg.exam_grade
				ELSE
					(reg.exam_grade*crun.exam_percentage + reg.lab_grade*(100 - crun.exam_percentage))/100
				END
				)
	INTO fin_grade
	FROM "Register" reg 
		JOIN "CourseRun" crun USING (course_code, serial_number)
	WHERE reg.amka = st_amka
		AND reg.course_code = course_code
		AND reg.serial_number = serial_num;
END;
$$ LANGUAGE 'plpgsql';




-- 7)
CREATE OR REPLACE FUNCTION student_total_semester_units(st_amka VARCHAR,
	OUT total_units INTEGER)
AS $$
BEGIN
	SELECT (COALESCE(SUM(course.units), 0)) INTO total_units
	FROM "Register" reg
		JOIN "CourseRun" crun USING (course_code, serial_number)
		JOIN "Semester" semester ON (semester.semester_id = crun.semesterrunsin)
		JOIN "Course" course USING (course_code)
	WHERE semester.semester_status = 'present'
		AND reg.register_status = 'approved'
		AND reg.amka = st_amka;
END;
$$ LANGUAGE 'plpgsql';



-- 8)
CREATE OR REPLACE FUNCTION check_course_requirements(st_amka VARCHAR,
	course_to_register CHARACTER(7), OUT meets_requirements BOOLEAN)
AS $$
BEGIN
	IF EXISTS (
		SELECT depends.main
		FROM "Course_depends" depends
		WHERE depends.dependent = course_to_register
			AND depends.mode = 'required'

		EXCEPT

		SELECT reg.course_code
		FROM "Register" reg
		WHERE reg.amka = st_amka
			AND reg.register_status = 'pass'
	)
	THEN 
		meets_requirements := FALSE;
	ELSE 
		meets_requirements := TRUE;
	END IF;
END;
$$ LANGUAGE 'plpgsql';


























-- Question 2





-- 2.3
-- Υλοποιήστε συνάρτηση για την εισαγωγή προγράμματος σπουδών. Η συνάρτηση θα παίρνει
-- ορίσματα το είδος του προγράμματος (1.τυπικό, 2. ξενόγλωσσο, 3. εποχιακό), τη γλώσσα (για
-- την περίπτωση του ξενόγλωσσου προγράμματος), την εποχή (για την περίπτωση εποχιακού
-- προγράμματος), το έτος έναρξης, τη διάρκεια και τις συνθήκες αποφοίτησης και θα δημιουργεί
-- στη βάση ένα νέο πρόγραμμα σπουδών. Δεν θα επιτρέπεται η εισαγωγή προγράμματος
-- σπουδών με έτος έναρξης παλαιότερο από το πιο πρόσφατο ανά είδος. Στη συνέχεια, για την
-- περίπτωση του τυπικού προγράμματος θα εισάγει τα μαθήματα και τους φοιτητές που έχουν
-- εγγραφεί στο τμήμα το ίδιο έτος με το έτος έναρξης του προγράμματος και μετά. Οι φοιτητές
-- αυτοί δεν πρέπει να παρακολουθούν κάποιο εποχιακό πρόγραμμα και αν έχουν συνδεθεί με
-- προηγούμενο τυπικό πρόγραμμα θα πρέπει να μεταφερθούν στο τρέχον. Στην περίπτωση του
-- ξενόγλωσσου προγράμματος θα εισάγονται εξωτερικοί φοιτητές του ίδιου έτους και ένας
-- τυχαίος αριθμός από φοιτητές που έχουν αποφοιτήσει από τυπικό πρόγραμμα σπουδών. Τέλος
-- για την περίπτωση εποχιακού προγράμματος θα εισάγεται ένας αριθμός από τυχαίους φοιτητές
-- και θα υλοποιήσετε μια συνάρτηση για την εισαγωγή ενοτήτων που θα δέχεται ως ορίσματα
-- τον κωδικό προγράμματος, τον κωδικό (!!!) ενότητας και μια λίστα από κωδικούς μαθημάτων.
CREATE OR REPLACE FUNCTION new_program(progr_type program_type, language VARCHAR, season VARCHAR, 
	year CHARACTER(4), duration INTEGER, min_courses INTEGER, min_credits INTEGER, obligatory BOOLEAN,
	committee_num INTEGER, dipl_type diploma_type) RETURNS VOID AS
$$
DECLARE
	max_id INTEGER; -- ID of last program inserted
	seasonal_insertions CONSTANT INTEGER := 20; -- arbitrary number of students inserted in seasonal program case
	seasonal_courses_per_unit CONSTANT INTEGER := 4; -- arbitrary number of courses per CustomUnit for seasonal program
	field_1 CONSTANT CHARACTER(3) := 'ΠΛΗ';
	field_2 CONSTANT CHARACTER(3) := 'ΗΡΥ';
	array_1 CHARACTER(7)[];
	array_2 CHARACTER(7)[];
BEGIN
	-- case typical program
	-- we check if the program we are trying to create
	-- is outdated, meaning there is already a newer program
	-- than the year we are given in arguments
	IF progr_type = 'typical' THEN
		-- find the last typical program's id inserted so that
		-- we use it incremented
		SELECT MAX("ProgramID") INTO max_id FROM "Program" WHERE type_of_program("ProgramID") = 'typical';
		IF max_id IS NULL THEN
			max_id := 1000;
		END IF;

		-- create the new program
		-- initialize it with zero students (we are adding them later
		-- updating the number of participants)
		INSERT INTO "Program"
		VALUES(max_id + 1, duration, min_courses, min_credits, obligatory,
				committee_num, dipl_type, 0, year);

		-- inserting a specific number of both obl and non-obl
		-- courses into the "offers" relation
		INSERT INTO "ProgramOffersCourse" ("ProgramID", "CourseCode") (
			SELECT max_id + 1, course.course_code
			FROM "Course" course
			WHERE course.obligatory
			ORDER BY RANDOM() LIMIT min_courses / 2
			)

			UNION
			
			(
			SELECT max_id + 1, course.course_code
			FROM "Course" course
			WHERE NOT course.obligatory
			ORDER BY RANDOM() LIMIT 2*min_courses
		);

		-- inserting students whose entry_date is later than
		-- the creation of the program
		-- AND
		-- they have not joined a seasonal program (the latest,
		-- so that we don't have issues with old "Joins")
		INSERT INTO "Joins" ("StudentAMKA", "ProgramID")
		SELECT student.amka, max_id + 1
		FROM "Student" student
		WHERE EXTRACT(YEAR FROM student.entry_date)::INTEGER >= year::INTEGER --ousiastika yearFoititi >= yearProgrammatos
			AND student.amka NOT IN (
				SELECT joins."StudentAMKA"
				FROM "Joins" joins
				WHERE type_of_program(joins."ProgramID") = 'seasonal'
				--"Οι φοιτητές αυτοί δεν πρέπει να παρακολουθούν κάποιο εποχιακό πρόγραμμα κ"
					AND joins."ProgramID" >= ALL (SELECT "ProgramID" FROM "SeasonalProgram") -- to teleftaio seasonal ! to pio recent ! 
				);

		-- count the number of students we 
		-- just inserted in Joins for the specific program
		-- and update the NumOfParticipants
		UPDATE "Program"
		SET "NumOfParticipants" = (
			SELECT COUNT(*) 
			FROM "Joins" joins
			WHERE joins."ProgramID" = max_id + 1
		)
		WHERE "ProgramID" = max_id + 1;


		-- delete the students we just inserted from
		-- any other joins with an older typical program
		-- carefully so we dont delete joins with a
		-- foreign language program
		-- (we dont have to check seasonal, we checked earlier)
		--και αν έχουν συνδεθεί με
		-- προηγούμενο τυπικό πρόγραμμα θα πρέπει να μεταφερθούν στο τρέχον. Στην ουσία έχουν προστεθεί στο τρέχον Join με maxid+1, αυτο που 
		-- μενει είναι να διαγραφούν όσοι έχουν id != (maxid+1) και συγκεκριμενα οσους εχουν αμκα που αντιστοιχει σε σχεση joins me maxid+1 .Ετσι
		-- σβηνουμε αυτους που μολις!! προστέθηκαν 
		DELETE FROM "Joins" joins
		WHERE joins."ProgramID" <> max_id + 1
			AND joins."StudentAMKA" IN (
				SELECT "StudentAMKA"
				FROM "Joins"
				WHERE "ProgramID" = max_id + 1
			)
			AND type_of_program(joins."ProgramID") = 'typical'; --και προφανώς αναφερόμαστε σε typical προγραμμα! 

-- Στην περίπτωση του
-- ξενόγλωσσου προγράμματος θα εισάγονται εξωτερικοί φοιτητές του ίδιου έτους και ένας
-- τυχαίος αριθμός από φοιτητές που έχουν αποφοιτήσει από τυπικό πρόγραμμα σπουδών

	-- case foreign language program
	-- we check if the program we are trying to create
	-- is outdated, meaning there is already a newer program
	-- than the year we are given in arguments
	ELSIF progr_type = 'foreign_language' THEN
		-- find the last foreign language program's id inserted so that
		-- we use it incremented
		SELECT MAX("ProgramID") INTO max_id FROM "ForeignLanguageProgram";
		IF max_id IS NULL THEN
			max_id := 2000;
		END IF;

		-- create the new program (and foreign language program)
		-- initialize it with zero students (we are adding them later
		-- updating the number of participants)
		INSERT INTO "Program"
		VALUES(max_id + 1, duration, min_courses, min_credits, obligatory,
			committee_num, dipl_type, 0, year);

		INSERT INTO "ForeignLanguageProgram" VALUES(max_id + 1, language);

		-- inserting a specific number of both obl and non-obl
		-- courses into the "offers" relation
		INSERT INTO "ProgramOffersCourse" ("ProgramID", "CourseCode") (
			SELECT max_id + 1, course.course_code
			FROM "Course" course
			WHERE course.obligatory
			ORDER BY RANDOM() LIMIT min_courses / 2
			)

			UNION
		(
			SELECT max_id + 1, course.course_code
			FROM "Course" course
			WHERE NOT course.obligatory
			ORDER BY RANDOM() LIMIT 2*min_courses
		);


		-- inserting "foreign" students whose entry_date same as
		-- the year of the creation of the program
		-- AND
		-- a random number of students graduated from a typical program
		INSERT INTO "Joins" ("StudentAMKA", "ProgramID") (
			SELECT student.amka, max_id + 1
			FROM "Student" student
			WHERE EXTRACT(YEAR FROM student.entry_date)::INTEGER = year::INTEGER
				AND SUBSTRING(student.am FROM 5 FOR 1) = '1' -- tsekaroyme oti X='1' , ara o foititis einai ksenoglossos 
			)
			
			UNION
			--θα εισαγεται και τυχαίος αριθμός από φοιτητές που έχουν αποφοιτήσει από τυπικό πρόγραμμα σπουδών
			(
			SELECT diploma."StudentAMKA", max_id + 1
			FROM "Diploma" diploma
			WHERE type_of_program(diploma."ProgramID") = 'typical'
			ORDER BY RANDOM() -- (rows ordered with random σειρα)
			LIMIT CEILING(
				RANDOM()*( --δε θες απλα random σειρα θες και random πληθος (αρα τυχαιο limit) οκ βλακεια μου 
					SELECT COUNT(DISTINCT "StudentAMKA")
					FROM "Diploma"
					WHERE type_of_program("ProgramID") = 'typical'
					)
				)
		);

		-- count the number of students we 
		-- just inserted in Joins for the specific program
		-- and update the NumOfParticipants
		UPDATE "Program" 
		SET "NumOfParticipants" = (
			SELECT COUNT(*) 
			FROM "Joins" joins
			WHERE joins."ProgramID" = max_id + 1
		)
		WHERE "ProgramID" = max_id + 1;
-- Τέλος
-- για την περίπτωση εποχιακού προγράμματος θα εισάγεται ένας αριθμός από τυχαίους φοιτητές
-- και θα υλοποιήσετε μια συνάρτηση για την εισαγωγή ενοτήτων που θα δέχεται ως ορίσματα
-- τον κωδικό προγράμματος, τον κωδικό (!!!) ενότητας και μια λίστα από κωδικούς μαθημάτων.
	ELSIF progr_type = 'seasonal' THEN
		-- find the last seasonal program's id inserted so that
		-- we use it incremented
		SELECT MAX("ProgramID") INTO max_id FROM "SeasonalProgram";
		IF max_id IS NULL THEN
			max_id := 3000;
		END IF;

		-- create the new program (and seasonal program)
		-- initialize it with zero students (we are adding them later
		-- updating the number of participants)
		INSERT INTO "Program"
		VALUES(max_id + 1, duration, min_courses, min_credits, obligatory,
			committee_num, dipl_type, 0, year::CHARACTER(4));
		INSERT INTO "SeasonalProgram" VALUES(max_id + 1, season);

		-- inserting #seasonal_insertions num students
		-- who have not joined a typical program (randomly)
		INSERT INTO "Joins" ("StudentAMKA", "ProgramID") (
			SELECT student.amka, max_id + 1
			FROM "Student" student 
			WHERE student.amka NOT IN (
				SELECT "StudentAMKA"
				FROM "Joins"
				WHERE type_of_program("ProgramID") = 'typical'
				)
			ORDER BY RANDOM() LIMIT seasonal_insertions
		);

		-- count the number of students we 
		-- just inserted in Joins for the specific program
		-- and update the NumOfParticipants
		UPDATE "Program" 
		SET "NumOfParticipants" = (
			SELECT COUNT(*) 
			FROM "Joins" joins
			WHERE joins."ProgramID" = max_id + 1
		)
		WHERE "ProgramID" = max_id + 1;

		-- insert random field_1 courses of the corresponding 
		-- season (of #seasonal_courses_per_unit number)
		SELECT ARRAY(
			SELECT course.course_code
			FROM "Course" course
			WHERE course.typical_season = (
				CASE
					WHEN season = 'winter' THEN
						'winter'
					ELSE
						'spring'
				END
			)::semester_season_type 
			AND LEFT(course.course_code, 3) = field_1
			ORDER BY RANDOM() LIMIT seasonal_courses_per_unit
		) INTO array_1;

		PERFORM insert_cust_units(max_id + 1, 1, VARIADIC array_1);

		-- insert random field_2 courses of the corresponding 
		-- season (of #seasonal_courses_per_unit number)
		SELECT ARRAY(
			SELECT course.course_code
			FROM "Course" course
			WHERE course.typical_season = (
				CASE
					WHEN season = 'winter' THEN
						'winter'
					ELSE
						'spring'
				END
			)::semester_season_type
			AND LEFT(course.course_code, 3) = field_2
			ORDER BY RANDOM() LIMIT seasonal_courses_per_unit
		) INTO array_2;

		PERFORM insert_cust_units(max_id + 1, 2, VARIADIC array_2);
	END IF;
END;
$$ LANGUAGE 'plpgsql';








/*
2.4. (*)
	Υλοποιήστε συνάρτηση για την εισαγωγή διατριβής.

	Η συνάρτηση θα δέχεται ως είσοδο
		1) τον αριθμό μητρώου ενός φοιτητή,
		2) τον τίτλο της διατριβής,
		3) πρόγραμμα σπουδών για το οποίο εκπονήθηκε.

	Η επιτροπή θα σχηματίζεται τυχαία από καθηγητές που διδάσκουν μαθήματα στο πρόγραμμα 
	και 
	θα ανατίθεται ένα τυχαίος βαθμός στο διάστημα [5-10].

	Αν ικανοποιούνται οι προϋποθέσεις λήψης διπλώματος/πτυχίου/πιστοποιητικού:
		θα υπολογίζεται ο τελικός βαθμός
		και
		θα δημιουργείται στο σύστημα ένα νέο δίπλωμα/πτυχίο/πιστοποιητικό.
*/
CREATE OR REPLACE FUNCTION insert_thesis(st_am CHARACTER(10), thesis_title VARCHAR,
	progr_id INTEGER)
RETURNS VOID AS
$$
DECLARE
	max_thesis_id INTEGER; -- ID of last thesis inserted
	max_dipl_id INTEGER; -- ID of last diploma inserted
	committee_number INTEGER; -- holds the num of committee members for this program
	dipl_grade NUMERIC; -- holds the grade of the diploma
	diploma_title CONSTANT VARCHAR := 'Νέο Δίπλωμα'; -- diploma title
BEGIN
	-- find the last thesis' id inserted so that
	-- we use it incremented
	SELECT MAX("ThesisID") INTO max_thesis_id FROM "Thesis";
	IF max_thesis_id IS NULL THEN
		max_thesis_id := 0;
	END IF;

	-- inserting new thesis in system with random grade as:
	-- 0 <= RANDOM() (NUMERIC) < 1
	-- 0 <= RANDOM()*6 (NUMERIC) < 6
	-- 0 <= FLOOR(RANDOM()*6) (INTEGER) <= 5
	-- 5 <= FLOOR(RANDOM()*6) + 5 (INTEGER) <= 10
	INSERT INTO "Thesis" ("ThesisID", "Grade", "Title", "StudentAMKA", "ProgramID")
	SELECT max_thesis_id + 1, (FLOOR(RANDOM() * 6) + 5)::NUMERIC, thesis_title, student.amka, progr_id
	FROM "Student" student
	WHERE student.am = st_am;

	-- comm num
	SELECT "CommitteeNum" INTO committee_number FROM "Program" WHERE "ProgramID" = progr_id;
	
	-- depending on the type of program, we are creating a committee
	-- and then setting a random member as the supervisor
	-- then we check if the student can graduate
	IF type_of_program(progr_id) = 'seasonal' THEN
		INSERT INTO "Committee" ("ProfessorAMKA", "ThesisID", "Supervisor")
		SELECT DISTINCT teach.amka, max_thesis_id + 1, FALSE
		FROM "RefersTo" refers
			JOIN "Teaches" teach ON (
				refers."CourseRunCode" = teach.course_code
				AND refers."CourseRunSerial" = teach.serial_number
				)
		WHERE refers."SeasonalProgramID" = progr_id
		LIMIT committee_number;

		-- set a random member of the committee as supervisor
		UPDATE "Committee" SET "Supervisor" = TRUE
		WHERE ("ThesisID", "ProfessorAMKA") IN (
			SELECT "ThesisID", "ProfessorAMKA"
			FROM "Committee"
			WHERE "ThesisID" = max_thesis_id + 1
			LIMIT 1
			);

		dipl_grade := check_student_certificate(st_am, progr_id);
	ELSE
		INSERT INTO "Committee" ("ProfessorAMKA", "ThesisID", "Supervisor")
		SELECT teach.amka, max_thesis_id + 1, FALSE
		FROM "ProgramOffersCourse" offers
			JOIN "Teaches" teach ON (offers."CourseCode" = teach.course_code)
		WHERE offers."ProgramID" = progr_id
		LIMIT committee_number;

		-- set a random member of the committee as supervisor
		UPDATE "Committee" SET "Supervisor" = TRUE
		WHERE ("ThesisID", "ProfessorAMKA") IN (
			SELECT "ThesisID", "ProfessorAMKA"
			FROM "Committee"
			WHERE "ThesisID" = max_thesis_id + 1
			LIMIT 1
			);

		dipl_grade := check_student_grad(st_am, progr_id);
	END IF;

	-- NULL means the student doesn't meet the
	-- graduation requirements
	IF dipl_grade IS NULL THEN
		RETURN;
	END IF;

	-- find the last diploma's id inserted so that
	-- we use it incremented
	SELECT MAX("DiplomaNum") INTO max_dipl_id FROM "Diploma";
	IF max_dipl_id IS NULL THEN
		max_dipl_id := 0;
	END IF;

	INSERT INTO "Diploma" ("DiplomaNum", "DiplomaGrade", "DiplomaTitle", "StudentAMKA", "ProgramID")
	SELECT max_dipl_id + 1, dipl_grade, diploma_title, st.amka, progr_id
	FROM "Student" st
	WHERE st.am = st_am;
END;
$$ LANGUAGE 'plpgsql';











-- Question 3





-- 3.5.
-- Εύρεση του τομέα ή των τομέων όπου εκπονήθηκαν οι
-- περισσότερες εργασίες βάσει του τύπου τους (χρήση του 
-- πεδίου DiplomaType). Ο τομέας εκπόνησης προκύπτει από
-- το εργαστήριο στο οποίο είναι ενταγμένος ο επιβλέπων καθηγητής.
CREATE OR REPLACE FUNCTION find_sector_with_most_projects()
	RETURNS TABLE (d_type diploma_type, sector INTEGER)
AS
$$
BEGIN
	RETURN QUERY
		SELECT p."DiplomaType", s.sector_code
		FROM "Program" p
			JOIN "Thesis" t USING ("ProgramID")
			JOIN "Committee" c USING ("ThesisID")
			JOIN "Professor" ON (c."ProfessorAMKA" = "Professor".amka)
			JOIN "Lab" ON ("Professor".labjoins = "Lab".lab_code)
			JOIN "Sector" s USING (sector_code)
		WHERE c."Supervisor"
		GROUP BY p."DiplomaType", s.sector_code
			HAVING COUNT(s.sector_code) >= ALL (
				SELECT COUNT(s.sector_code)
				FROM "Program" p2
					JOIN "Thesis" t2 USING ("ProgramID")
					JOIN "Committee" c2 USING ("ThesisID")
					JOIN "Professor" ON (c2."ProfessorAMKA" = "Professor".amka)
					JOIN "Lab" ON ("Professor".labjoins = "Lab".lab_code)
					JOIN "Sector" s USING (sector_code)
				WHERE c2."Supervisor" AND p2."DiplomaType" = p."DiplomaType"--προσοχή! ιδιο diploma type.
				GROUP BY s.sector_code
			);
END;
$$ LANGUAGE 'plpgsql';


SELECT find_sector_with_most_projects();

-- 3.6. Ανάκτηση του αριθμού μητρώου των φοιτητών που ικανοποιούν
-- τις προϋποθέσεις αποφοίτησης και δεν έχουν ακόμη αποφοιτήσει 
-- για ένα συγκεκριμένο τυπικό ή ξενόγλωσσο πρόγραμμα σπουδών.
CREATE OR REPLACE FUNCTION students_able_to_grad(progr_id INTEGER) RETURNS SETOF CHARACTER(10) AS
$$
DECLARE
	temp_am VARCHAR;
BEGIN
	-- loop for the students that have not graduated
	-- and see if they can (then return them)
	FOR temp_am IN (
		SELECT am
		FROM "Joins" JOIN "Student" ON (amka = "StudentAMKA")
		WHERE "ProgramID" = progr_id
			AND amka NOT IN (
				SELECT "StudentAMKA"
				FROM "Diploma"
				WHERE "ProgramID" = progr_id
			)
		)
	LOOP
		IF NOT (check_student_grad(temp_am, progr_id) IS NULL) THEN
			RETURN NEXT temp_am;
		END IF;
	END LOOP;
END;
$$ LANGUAGE 'plpgsql';




-- 3.7. Εύρεση του φόρτου όλου του εργαστηριακού προσωπικού το τρέχον εξάμηνο.
-- Ο φόρτος υπολογίζεται ως το άθροισμα των ωρών εργαστηρίου για τα μαθήματα
-- που υποστηρίζει κάθε μέλος του εργαστηριακού προσωπικού. Το αποτέλεσμα είναι
-- πλειάδες της μορφής: ΑΜΚΑ, επώνυμο, όνομα, άθροισμα ωρών. Κάθε πλειάδα του
-- αποτελέσματος αντιστοιχεί σε ένα μέλος εργαστηριακού προσωπικού. Στο αποτέλεσμα
-- να εμφανίζονται όλα τα μέλη εργαστηριακού προσωπικού, ακόμη και αν έχουν μηδενικό φόρτο.
CREATE OR REPLACE FUNCTION workload_of_lab_teachers()
RETURNS TABLE(lab_amka CHARACTER VARYING, lab_surname CHARACTER VARYING(30), lab_name CHARACTER VARYING(30), work_hours BIGINT) AS
$$
BEGIN
	RETURN QUERY
		SELECT lab_teacher.amka, lab_teacher.surname, lab_teacher.name,
			SUM(CASE 
				WHEN semester.semester_status = 'present' THEN
					course.lab_hours
				ELSE 
					0
				END) AS lab_hours_sum
		FROM "Person" lab_teacher
			LEFT JOIN "Supports" supports USING (amka)
			JOIN "CourseRun" crun USING (course_code, serial_number)
			JOIN "Semester" semester ON crun.semesterrunsin = semester.semester_id
			JOIN "Course" course USING (course_code)
		GROUP BY lab_teacher.amka;
END;
$$ LANGUAGE 'plpgsql';


-- 3.8. Ανάκτηση όλων των μαθημάτων που είναι προαπαιτούμενα ή συνιστώμενα,
-- άμεσα ή έμμεσα, για ένα συγκεκριμένο μάθημα του οποίου δίνεται ο κωδικός. 
-- Το αποτέλεσμα είναι πλειάδες της μορφής: κωδικός μαθήματος, τίτλος μαθήματος.
CREATE OR REPLACE FUNCTION relative_courses(course_code CHARACTER(7)) RETURNS
TABLE(relative_code CHARACTER(7), relative_title CHARACTER(100)) AS
$$
BEGIN
	RETURN QUERY
		WITH Recursive
		Req(d, m) AS (
			SELECT dependent AS d, main AS m
			FROM "Course_depends"
			WHERE dependent = $1

			UNION

			SELECT Req.d, "Course_depends".main AS d
			FROM Req JOIN "Course_depends"
				ON Req.m = "Course_depends".dependent
		)
		SELECT Req.m, course.course_title
		FROM Req JOIN "Course" course ON (course.course_code = Req.m);
END;
$$ LANGUAGE 'plpgsql';


-- 3.9. Ανάκτηση των ονομάτων όλων των καθηγητών που
-- συμμετέχουν σε όλους τους τύπους προγραμμάτων σπουδών.
CREATE OR REPLACE FUNCTION teach_all_progr_types() RETURNS
	TABLE(prof_name CHARACTER VARYING(30), prof_surname CHARACTER VARYING(30))
AS
$$
BEGIN
	RETURN QUERY
		SELECT prof.name AS prof_name, prof.surname AS prof_surname
		FROM "Person" prof
			JOIN "Teaches" USING (amka)
			JOIN "CourseRun" crun USING (course_code, serial_number)
			JOIN "ProgramOffersCourse" off ON (off."CourseCode" = crun.course_code)
			JOIN "Semester" semester ON (semester.semester_id = crun.semesterrunsin)
		WHERE semester.semester_status = 'present'
			AND NOT EXISTS (
				SELECT unnest(enum_range(NULL::program_type)) AS pr_type

				EXCEPT

				SELECT type_of_program(off."ProgramID") AS pr_type
				FROM "Person" prof2
					JOIN "Teaches" USING (amka)
					JOIN "CourseRun" crun USING (course_code, serial_number)
					JOIN "ProgramOffersCourse" off ON (off."CourseCode" = crun.course_code)
					JOIN "Semester" semester ON (semester.semester_id = crun.semesterrunsin)
				WHERE semester.semester_status = 'present'
					AND prof2.amka = prof.amka
			);
END;
$$ LANGUAGE 'plpgsql';








-- Question 4






-- 4.1..3. κατά την μεταβολή ενός μελλοντικού εξαμήνου
-- σε τρέχον (ενημέρωση από future σε present) θα γίνεται
-- αυτόματη δημιουργία προτεινόμενων εγγραφών φοιτητών σε
-- εξαμηνιαία μαθήματα του τρέχοντος εξαμήνου.
CREATE OR REPLACE FUNCTION semester_future_to_present()
RETURNS TRIGGER AS $$
BEGIN
	IF OLD.semester_status = 'future' AND NEW.semester_status = 'present' THEN
		INSERT INTO "Register" ("amka", "serial_number", "course_code", "exam_grade", "lab_grade", "register_status")
		SELECT student.amka, crun.serial_number, crun.course_code, NULL, NULL, 'proposed'
		FROM "CourseRun" crun
			JOIN "Course" course USING (course_code)
			JOIN "Student" student ON
				(EXTRACT(YEAR FROM student.entry_date)::INTEGER + course.typical_year - 1 = EXTRACT(YEAR FROM NEW.end_date)::INTEGER)
		WHERE crun.semesterrunsin = NEW.semester_id
			AND course.typical_season = NEW.academic_season
			AND student.amka NOT IN (
				SELECT diploma."StudentAMKA"
				FROM "Diploma" diploma
			);
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS semester_future_to_present_trig ON "Semester";
CREATE TRIGGER semester_future_to_present_trig
AFTER UPDATE ON "Semester"
FOR EACH ROW EXECUTE PROCEDURE semester_future_to_present();


-- Δεν επιτρέπεται δύο ή περισσότερα εξάμηνα να είναι ταυτόχρονα σε κατάσταση «present».
CREATE OR REPLACE FUNCTION present_status()
RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.semester_status = 'present'
		AND
		(SELECT COUNT(*) FROM "Semester" WHERE semester_status = 'present' LIMIT 1) <> 0
	) THEN
		RETURN NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS present_status_trig ON "Semester";
CREATE TRIGGER present_status_trig
BEFORE INSERT OR UPDATE ON "Semester"
FOR EACH ROW EXECUTE PROCEDURE present_status();


-- 4.1..4. κατά το κλείσιμο του τρέχοντος εξαμήνου (ενημέρωση από present σε past)
-- θα γίνεται αυτόματος υπολογισμός της τελικής βαθμολογίας και της κατάστασης
-- (pass/fail) των εγγραφών φοιτητών στα μαθήματα.
CREATE OR REPLACE FUNCTION semester_present_to_past()
RETURNS TRIGGER AS $$
BEGIN
	IF OLD.semester_status = 'present' AND NEW.semester_status = 'past' THEN
		UPDATE "Register"
		SET final_grade = calculate_grade(amka, course_code, serial_number),
			register_status = (CASE WHEN final_grade >= 5 THEN 'pass'::register_status_type
							   ELSE 'fail'::register_status_type END)
		WHERE (course_code, serial_number) IN (
			SELECT cr.course_code, cr.serial_number
			FROM "CourseRun" cr
			WHERE cr.semesterrunsin = NEW.semester_id
			)
			AND register_status = 'approved'::register_status_type;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS semester_present_to_past_trig ON "Semester";
CREATE TRIGGER semester_present_to_past_trig
AFTER UPDATE ON "Semester"
FOR EACH ROW EXECUTE PROCEDURE semester_present_to_past();




-- 4.2. Δεν θα επιτρέπεται η εισαγωγή προγράμματος σπουδών 
-- με έτος έναρξης παλαιότερο από τον πιο πρόσφατο ανά τύπο.
CREATE OR REPLACE FUNCTION inserting_progr_year()
RETURNS TRIGGER AS $$
DECLARE
	latest_program INTEGER;
BEGIN
	SELECT MAX("Year"::INTEGER)::INTEGER
	INTO latest_program
	FROM "Program"
	WHERE type_of_program("ProgramID") = type_of_program(NEW."ProgramID");

	IF (NEW."Year"::INTEGER < latest_program) THEN
		RETURN NULL;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS inserting_progr_year_trigger ON "Program";
CREATE TRIGGER inserting_progr_year_trigger
BEFORE INSERT OR UPDATE ON "Program"
FOR EACH ROW EXECUTE PROCEDURE inserting_progr_year();




-- Πρέπει να υπάρχει αυτόματος έλεγχος μέγιστου 
-- επιτρεπόμενου (από το πρόγραμμα) αριθμού μελών κατά 
-- την εισαγωγή μελών επιτροπής διατριβής.
CREATE OR REPLACE FUNCTION max_comm_num()
RETURNS TRIGGER AS $$
BEGIN
	IF ((SELECT COUNT(*) FROM "Committee" WHERE "ThesisID" = NEW."ThesisID" LIMIT 1) >=
		(SELECT "NumOfParticipants" FROM "Program" JOIN "Thesis" USING ("ProgramID")
			WHERE "ThesisID" = NEW."ThesisID" LIMIT 1))
	THEN
		RETURN NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS max_comm_num_trigger ON "Committee";
CREATE TRIGGER max_comm_num_trigger
BEFORE INSERT ON "Committee"
FOR EACH ROW EXECUTE PROCEDURE max_comm_num();




-- 4.3. (*) Αυτόματος έλεγχος εγκυρότητας εγγραφής φοιτητή σε εξαμηνιαίο μάθημα ώστε να
-- ικανοποιούνται οι περιορισμοί προ-απαιτούμενων μαθημάτων και οι συνολικές
-- πιστωτικές μονάδες που θα παρακολουθήσει ο φοιτητής μαζί με το εν λόγω μάθημα να
-- μην υπερβαίνουν τις 50 πιστωτικές μονάδες. Ενεργοποιείται όταν η κατάσταση εγγραφής
-- «register_status» ενημερωθεί από «proposed» ή «requested» σε «approved». Αν ο έλεγχος
-- αποτύχει τότε η κατάσταση γίνεται «rejected».
CREATE OR REPLACE FUNCTION check_course_requirements()
RETURNS TRIGGER AS $$
DECLARE
	student_amka VARCHAR;
BEGIN
	IF (OLD.register_status = 'proposed'
		OR OLD.register_status = 'requested'
		AND NEW.register_status = 'approved')
	THEN
		IF (SELECT (student_total_semester_units(NEW.amka) + course.units) AS sum_units
			FROM "Course" course
			WHERE course.course_code = NEW.course_code
			LIMIT 1
			> 50

			OR

			NOT check_course_requirements(NEW.amka, NEW.course_code)
		)
		THEN
			NEW.register_status = 'rejected';
		END IF;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS check_course_requirements_trigger ON "Register";
CREATE TRIGGER check_course_requirements_trigger
BEFORE UPDATE ON "Register"
FOR EACH ROW EXECUTE PROCEDURE check_course_requirements();