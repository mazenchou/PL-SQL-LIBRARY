
--create function login customer and employee--
--customer
CREATE OR REPLACE PROCEDURE loginCustomer_library(user IN VARCHAR2, pass IN VARCHAR2)
IS
  passAux customer.password%TYPE;
  incorrect_password EXCEPTION;
BEGIN
   
   
  SELECT password INTO passAux
  FROM customer
  WHERE username LIKE user;
  
  IF passAux LIKE pass THEN
    DBMS_OUTPUT.PUT_LINE('User ' || user || ' loging succesfull');
  ELSE
    RAISE incorrect_password;
  END IF;
  
  EXCEPTION
  WHEN no_data_found OR incorrect_password THEN 
       DBMS_OUTPUT.PUT_LINE('Incorrect username or password');
                                   
END;
--employee
CREATE OR REPLACE PROCEDURE loginEmployee_library(user IN VARCHAR2, pass IN VARCHAR2)
IS
  passAux employee.password%TYPE;
  incorrect_password EXCEPTION;
BEGIN
  SELECT password INTO passAux
  FROM employee
  WHERE username LIKE user;
  
  IF passAux LIKE pass THEN
    DBMS_OUTPUT.PUT_LINE('User ' || user || ' loging succesfull');
  ELSE
    RAISE incorrect_password;
  END IF;
  
  EXCEPTION
  WHEN no_data_found OR incorrect_password THEN 
       DBMS_OUTPUT.PUT_LINE('Incorrect username or password');
END;

--perform functions
SET SERVEROUTPUT ON;
DECLARE
  user customer.username%TYPE;
  pass customer.password%TYPE;
BEGIN
  user := &Username;
  pass := &Password;
  login_library(user,pass);
END;

SET SERVEROUTPUT ON;
DECLARE
  user employee.username%TYPE;
  pass employee.password%TYPE;
BEGIN
  user := &Username;
  pass := &Password;
  login_employee_library(user,pass);
END;


---------------------------------------
--create a view to affich
CREATE OR REPLACE PROCEDURE viewItem_library(VItemID IN VARCHAR2)
IS
  VISBN VARCHAR2(4);
  VTitle VARCHAR2(50);
  VYear NUMBER;
  VState VARCHAR2(10);
  VDebyCost NUMBER(10,2);
  VLostCost NUMBER(10,2);
  VAddress VARCHAR2(50);
  VAbala VARCHAR2(1);
 
BEGIN
 
   if VItemID = (select bookid from book )then
    SELECT isbn, state, avalability, debycost, lostcost, address
    INTO VISBN, VState, VAbala, VDebyCost, VLostCost, VAddress
    FROM book
    WHERE bookid LIKE VItemID;
  
    DBMS_OUTPUT.PUT_LINE('BOOK ' || VItemID );
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('ISBN: ' || VISBN);
    DBMS_OUTPUT.PUT_LINE('STATE: ' || VState);
    DBMS_OUTPUT.PUT_LINE('AVALABILITY: ' || VAbala);
    DBMS_OUTPUT.PUT_LINE('DEBY COST: ' || VDebyCost);
    DBMS_OUTPUT.PUT_LINE('LOST COST: ' || VLostCost);
    DBMS_OUTPUT.PUT_LINE('ADDRESS: ' || VAddress);
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');
  ELSIF VItemID like (select videoid from video ) THEN
    SELECT title, year, state, avalability, debycost, lostcost, address
    INTO VTitle, VYear, VState, VAbala, VDebyCost, VLostCost, VAddress
    FROM video
    WHERE videoid LIKE VItemID;
  
    DBMS_OUTPUT.PUT_LINE('VIDEO ' || VItemID );
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('TITLE: ' || VTitle);
    DBMS_OUTPUT.PUT_LINE('YEAR: ' || VYear);
    DBMS_OUTPUT.PUT_LINE('STATE: ' || VState);
    DBMS_OUTPUT.PUT_LINE('AVALABILITY: ' || VAbala);
    DBMS_OUTPUT.PUT_LINE('DEBY COST: ' || VDebyCost);
    DBMS_OUTPUT.PUT_LINE('LOST COST: ' || VLostCost);
    DBMS_OUTPUT.PUT_LINE('ADDRESS: ' || VAddress);
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');
  END IF;
END;

SET SERVEROUTPUT ON;
DECLARE
  VItemID VARCHAR2(10);
BEGIN
  VItemID := &Item_ID;
  viewItem_library(VItemID);
END;

--find the account of customers and employees with fines and rents
--CUSTOMER--
CREATE OR REPLACE PROCEDURE customerAccount_library(custoID IN customer.customerid%TYPE)
IS
  auxCard NUMBER;
  auxFines NUMBER;
  auxItem VARCHAR(6);
  
BEGIN
  SELECT cardnumber INTO auxCard
  FROM customer
  WHERE customerid LIKE custoID;
  
  
  DBMS_OUTPUT.PUT_LINE('The user card is ' || auxCard);  
  
  IF auxcard in (select cardid from rent ) THEN
    SELECT rent.itemid INTO auxItem
    FROM rent,card
    --jointure 
    WHERE card.cardid = rent.cardid
    AND card.cardid LIKE auxCard;    
    
    DBMS_OUTPUT.PUT_LINE('The user has ' || auxItem || ' rented');
  ELSE    
    DBMS_OUTPUT.PUT_LINE('This user has no rents'); 
  END IF;
  
  SELECT fines INTO auxFines
  FROM card
  WHERE cardid LIKE auxcard;
  
  DBMS_OUTPUT.PUT_LINE('The user fines are ' || auxFines);
    
  EXCEPTION WHEN no_data_found THEN 
  DBMS_OUTPUT.PUT_LINE('NOT DATA FOUND');
END;


--EMPLOYEE--
CREATE OR REPLACE PROCEDURE employeeAccount_library(emploID IN employee.employeeid%TYPE)
IS
  auxCard NUMBER;
  auxFines NUMBER;
  auxItem VARCHAR(6);
  
BEGIN
  SELECT cardnumber INTO auxCard
  FROM employee
  WHERE employeeid LIKE emploID;

  
  DBMS_OUTPUT.PUT_LINE('The user card is ' || auxCard);  
 IF auxcard in (select cardid from rent ) THEN
    SELECT rent.itemid INTO auxItem
    FROM rent,card
    WHERE card.cardid = rent.cardid
    AND card.cardid LIKE auxCard;    
    
    DBMS_OUTPUT.PUT_LINE('The user has ' || auxItem || ' rented');
  ELSE    
    DBMS_OUTPUT.PUT_LINE('This user has no rents'); 
  END IF;
  
  SELECT fines INTO auxFines
  FROM card
  WHERE cardid LIKE auxcard;
  
  DBMS_OUTPUT.PUT_LINE('The user fines are ' || auxFines);
    
  EXCEPTION WHEN no_data_found THEN 
  DBMS_OUTPUT.PUT_LINE('NOT DATA FOUND');
END;

--excuter 

SET SERVEROUTPUT ON;
DECLARE
  custoID customer.customerid%TYPE;
BEGIN
  custoID := &Customer_ID;
  customerAcount_library(custoID);
END;

SET SERVEROUTPUT ON;
DECLARE
  emploID employee.employeeid%TYPE;
BEGIN
  emploID := &Employee_ID;
  employeeAcount_library(emploID);
END;



-------------------------------------------------------------


-- here the person get video or book and we insert new rent and block the avaiblity
CREATE OR REPLACE PROCEDURE rentItem_library(aCard IN NUMBER, aItemID IN VARCHAR2, itemType IN VARCHAR2, aDate IN DATE)
IS
  statusA VARCHAR2(1);
  itemStatus VARCHAR2(1);
BEGIN
  --- the user is unblock to get a book or a video 
  SELECT status INTO statusA
  FROM card
  WHERE cardid LIKE aCard;
   -- status is valaid mean the user can get from the lib 
  IF statusA LIKE 'A' THEN
    -- book 
    IF itemType LIKE 'book' THEN
      SELECT avalability INTO itemStatus
      FROM book
      WHERE bookid LIKE aItemID;
        --status  valaid mean the book exsit
      IF itemStatus LIKE 'A' THEN
        UPDATE book
        SET avalability = 'O'
        WHERE bookid LIKE aItemID;
         -- insert or create new rent 
        INSERT INTO rent
        VALUES (aCard,aItemID,sysdate,aDate);
        DBMS_OUTPUT.PUT_LINE('Item ' || aItemID || ' rented');
        --book does't exsit or taken 
      ELSE
        DBMS_OUTPUT.PUT_LINE('The item is already rented');
      END IF;
     --- video  
    ELSIF itemType LIKE 'video' THEN
     
      SELECT avalability INTO itemStatus
      FROM video
      WHERE videoid LIKE aItemID;
      
      IF itemStatus LIKE 'A' THEN
        UPDATE video
        SET avalability = 'O'
        WHERE videoid LIKE aItemID;
        
        INSERT INTO rent
        VALUES (aCard,aItemID,sysdate,aDate);
        DBMS_OUTPUT.PUT_LINE('Item ' || aItemID || ' rented');
      ELSE
        DBMS_OUTPUT.PUT_LINE('The item is already rented');
      END IF;
    
  ELSE
    DBMS_OUTPUT.PUT_LINE('The user is blocked');
  END IF;    
END;

-- difference between auxcard and acard (varaible local , varaible declaree) 
SET SERVEROUTPUT ON ;
DECLARE
  auxCard NUMBER;
  auxItemID VARCHAR2(10);
  itemType VARCHAR2(20);
  auxDate DATE;
BEGIN
  auxCard := &Card_ID;
  itemType := &Item_Type_book_or_video;  
  auxItemID := &ID_Item;  
  auxDate := &Return_date;
  rentItem_library(auxCard,auxItemID,itemType,auxDate);
END;

SELECT * FROM customer;
SELECT * FROM rent;
SELECT * FROM card;




---------------------------------------------
--update information custmoer and employe --
--CUSTOMER--
CREATE OR REPLACE PROCEDURE updateInfoCusto_library(auxCustomer IN customer.customerid%TYPE, pNumber NUMBER, address VARCHAR2, newPass VARCHAR2)
IS
BEGIN
  UPDATE customer
  SET phone = pNumber, customeraddress = address, password = newPass
  WHERE customerid = auxCustomer;
END;



--EMPLOYEE--
CREATE OR REPLACE PROCEDURE updateInfoEmp_library(auxEmployee IN employee.employeeid%TYPE, pNumber NUMBER, address VARCHAR2, newPass VARCHAR2, newPayCheck NUMBER,
newBranch VARCHAR2)
IS
BEGIN
  UPDATE employee
  SET phone = pNumber, customeraddress = address, password = newPass, paycheck = auxEmployee, branchname = newBranch
  WHERE employeeid = auxEmployee;
END;



SET SERVEROUTPUT ON;
DECLARE
  auxCustomer customer.customerid%TYPE;
  pNumber NUMBER;
  address VARCHAR2;
  newPass VARCHAR2;
BEGIN
  auxCustomer := &Customer_ID;
  pNumber := &Write_your_phone_number;
  address := &Write_your_address;
  newPass := &Write_your_password;
  updateInfo_library(auxCustomer,pNumber,address,newPass);
END;


SET SERVEROUTPUT ON;
DECLARE
  auxEmployee emplouee.employeeid%TYPE;
  pNumber NUMBER;
  address VARCHAR2;
  newPass VARCHAR2;
  newPayCheck NUMBER;
  newBranch VARCHAR2;
BEGIN
  auxCustomer := &Customer_ID;
  pNumber := &Write_your_phone_number;
  address := &Write_your_address;
  newPass := &Write_your_password;
  newPayCheck := &Write_your_paycheck;
  newBranch := &Write_your_branch;
  updateInfoEmployee_library(auxCustomer,pNumber,address,newPass,newPayCheck,newBranch);
END;

------------------------------------------------------
--add customer--
CREATE OR REPLACE PROCEDURE addCustomer_library(auxCustomerId IN NUMBER, auxName IN VARCHAR2, auxCustomerAddress IN VARCHAR2, auxPhone IN NUMBER,
auxPass IN VARCHAR2, auxUserName IN VARCHAR2, auxCardNumber IN NUMBER)
IS
BEGIN
  INSERT INTO customer
  VALUES (auxCustomerId,auxName,auxCustomerAddress,auxPhone,auxPass,auxUserName,sysdate,auxCardNumber);
END;

SET SERVEROUTPUT ON;
DECLARE
  auxCustomerId NUMBER;
  auxName VARCHAR2(20);
  auxCustomerAddress VARCHAR2(20);
  auxPhone NUMBER;
  auxPass VARCHAR2(20);
  auxUserName VARCHAR2(20);
  auxCardNumber NUMBER;
BEGIN
  auxCustomerId := &Customer_ID;
  auxName := &Name;
  auxCustomerAddress := &Address;
  auxPhone := &Phone;
  auxPass := &Password;
  auxUserName := &User_Name;
  auxCardNumber := &Card_Numeber;
  addCustomer_library(auxCustomerId,auxName,auxCustomerAddress,auxPhone,auxPass,auxUserName,auxCardNumber);
END;

--------------------------------------------------------------------
--add book or video --
--BOOK--
CREATE OR REPLACE PROCEDURE addBook_library(auxISBN IN VARCHAR2, auxBookID IN VARCHAR2, auxState IN VARCHAR2, auxDebyCost IN NUMBER,
auxLostCost IN NUMBER, auxAddress IN VARCHAR2)
IS
BEGIN
  INSERT INTO book
  VALUES(auxISBN,auxBookID,auxState,'A',auxDebyCost,auxLostCost,auxAddress);
  DBMS_OUTPUT.PUT_LINE('Book inserted correctly');
END;

--VIDEO--
CREATE OR REPLACE PROCEDURE addVideo_library(auxTitle IN VARCHAR2, auxYear IN INT, auxVideoID IN VARCHAR2, auxState IN VARCHAR2, auxDebyCost IN NUMBER,
auxLostCost IN NUMBER, auxAddress IN VARCHAR2)
IS
BEGIN
  INSERT INTO video
  VALUES(auxTitle,auxYear,auxVideoID,auxState,'A',auxDebyCost,auxLostCost,auxAddress);
  DBMS_OUTPUT.PUT_LINE('Video inserted correctly');
END;

--EXAMPLES--
SET SERVEROUTPUT ON;
DECLARE
  auxISBN VARCHAR2(4);
  auxItemID VARCHAR2(6);
  auxState VARCHAR2(10);
  auxDebyCost NUMBER(10,2);
  auxLostCost NUMBER(10,2);
  auxAddress VARCHAR2(50);
BEGIN
    auxISBN := &ISBN;
    auxItemID := &ItemID;
    auxState := &State;
    auxDebyCost := &Deby_Cost;
    auxLostCost := &Lost_Cost;
    auxAddress := &Location;
    addBook_library(auxISBN, auxItemID, auxState, auxDebyCost, auxLostCost, auxAddress);
END;


-- examples to exucter fct 
SET SERVEROUTPUT ON;
DECLARE
  auxTitle VARCHAR2(50);
  auxYear INT;
  auxItemID VARCHAR2(6);
  auxState VARCHAR2(10);
  auxDebyCost NUMBER(10,2);
  auxLostCost NUMBER(10,2);
  auxAddress VARCHAR2(50);
BEGIN
    auxTitle := &Title;
    auxYear := &Year;
    auxItemID := &ItemID;
    auxState := &State;
    auxDebyCost := &Deby_Cost;
    auxLostCost := &Lost_Cost;
    auxAddress := &Location;
    addVideo_library(auxTitle, auxYear, auxItemID, auxState, auxDebyCost, auxLostCost, auxAddress);
END;


SELECT * FROM book;
SELECT * FROM video;


-----------------------------------------------------------------------------
--13--
-- delete item
CREATE OR REPLACE PROCEDURE removeItem_library(auxItemID IN VARCHAR2)
IS
  auxBook NUMBER;
  auxVideo NUMBER;
BEGIN
  SELECT COUNT(*) INTO auxBook
  FROM book
  WHERE bookid LIKE auxItemID;
  
  SELECT COUNT(*) INTO auxVideo
  FROM video
  WHERE videoid LIKE auxItemID;
  
  IF auxBook > 0 THEN
    DELETE FROM book
    WHERE bookid LIKE auxItemID;
    DBMS_OUTPUT.PUT_LINE('Book removed correctly');
  ELSIF auxVideo > 0 THEN
    DELETE FROM video
    WHERE videoid LIKE auxItemID;
    DBMS_OUTPUT.PUT_LINE('Video removed correctly');
  END IF;
END;

SET SERVEROUTPUT ON;
DECLARE
  auxItemID VARCHAR2(10);
BEGIN
  auxItemID := &ItemID_to_remove;
  removeItem_library(auxItemID);
END;

------------------------------------------------------------------------------------------------------------
-- affich information customer
--14--
CREATE OR REPLACE PROCEDURE viewCustomer_library(auxCustomerID IN NUMBER)
IS
  custoName VARCHAR2(40);
  custoAdd VARCHAR2(50);
  custoPhone NUMBER(9);
  userNaM VARCHAR2(10);
  custoDate DATE;
  custoCard NUMBER;
BEGIN
  SELECT name,customeraddress,phone,username,datesignup,cardnumber
  INTO custoName, custoAdd, custoPhone, userNaM, custoDate, custoCard
  FROM customer
  WHERE customerid LIKE auxCustomerID;
  
  DBMS_OUTPUT.PUT_LINE('CUSTOMER ' || auxCustomerID);
  DBMS_OUTPUT.PUT_LINE('------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('NAME: ' || custoName);
  DBMS_OUTPUT.PUT_LINE('ADDRESS: ' || custoAdd);
  DBMS_OUTPUT.PUT_LINE('PHONE: ' || custoPhone);
  DBMS_OUTPUT.PUT_LINE('USER NAME: ' || userNaM);
  DBMS_OUTPUT.PUT_LINE('DATE OF SIGN UP: ' || custoDate);
  DBMS_OUTPUT.PUT_LINE('CARD NUMBER: ' || custoCard);
  DBMS_OUTPUT.PUT_LINE('------------------------------------------');
  
END;

SET SERVEROUTPUT ON;
DECLARE
  auxCustoID VARCHAR2(10);
BEGIN
  auxCustoID := &CustomerID;
  viewCustomer_library(auxCustoID);
END;




