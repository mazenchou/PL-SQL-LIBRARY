
-- when we create card , status =A and fines=0 --
--CUSTOMER--
CREATE OR REPLACE TRIGGER addCardCusto_library
AFTER INSERT
ON customer
FOR EACH ROW
DECLARE
BEGIN
  INSERT INTO card
  VALUES (:new.cardnumber,'A',0);
  
  DBMS_OUTPUT.PUT_LINE('Card created');
END;

--EMPLOYEE--
CREATE OR REPLACE TRIGGER addCardEmp_library
AFTER INSERT
ON employee
FOR EACH ROW
DECLARE
BEGIN
  INSERT INTO card
  VALUES (:new.cardnumber,'A',0);
  
  DBMS_OUTPUT.PUT_LINE('Card created');
END;

--EXAMPLE--
INSERT INTO customer
VALUES (11,'MARI CARMEN','CORDOBA',645892456,'maricarmen123','ma11',sysdate,111);



-------------------------------------------------------------------------------------
-- pay fines --
CREATE OR REPLACE PROCEDURE payFines_library(auxCard IN card.cardid%TYPE, money IN NUMBER)
IS
  finesAmount NUMBER;
  total NUMBER;
BEGIN
  SELECT fines INTO finesAmount
  FROM card
  WHERE cardid LIKE auxCard;
  
  IF finesAmount < money THEN
    total := money - finesAmount;
    DBMS_OUTPUT.PUT_LINE('YOU PAY ALL YOUR FINES AND YOU HAVE ' || total || ' MONEY BACK');
    
    UPDATE card
    SET status = 'A', fines = 0
    WHERE cardid = auxCard;
    
  ELSIF finesAmount = money THEN
    total := money - finesAmount;
    DBMS_OUTPUT.PUT_LINE('YOU PAY ALL YOUR FINES');
    
    UPDATE card
    SET status = 'A', fines = 0
    WHERE cardid = auxCard;
  
  ELSE
    total := finesAmount - money;
    DBMS_OUTPUT.PUT_LINE('YOU WILL NEED TO PAY ' || total || ' MORE DOLLARS TO UNLOCK YOUR CARD');
    
    UPDATE card
    SET fines = total
    WHERE cardid = auxCard;
  END IF;
END;

SET SERVEROUTPUT ON;
DECLARE
  auxCard card.cardid%TYPE;
  money NUMBER;
BEGIN
  auxCard := &Card_ID;
  money := &Money_To_Pay;
  payFines_library(custoID);
END;


----------------------------------------------------------------------

-- return a book or a video 

CREATE OR REPLACE PROCEDURE handleReturns_library(auxItemID IN VARCHAR2)
IS
  BEGIN
  IF auxItemID in (select itemid from rent )  THEN
    DELETE FROM rent
    WHERE itemid = auxItemID;
    IF auxItemID in (select bookid from book ) THEN
      UPDATE book
      SET avalability = 'A'
      WHERE bookid LIKE auxItemID;
      DBMS_OUTPUT.PUT_LINE('The book ' || auxItemID || ' is now avaible.');
    ELSIF auxItemID in (select videoid from video ) THEN
      UPDATE video
      SET avalability = 'A'
      WHERE videoid LIKE auxItemID;
      DBMS_OUTPUT.PUT_LINE('The video ' || auxItemID || ' is now avaible.');
    END IF;
  ELSE
    DBMS_OUTPUT.PUT_LINE('This item is not rented at the moment');
  END IF;
  EXCEPTION WHEN no_data_found THEN 
  DBMS_OUTPUT.PUT_LINE('Item ID incorrect');    
END;

SET SERVEROUTPUT ON;
DECLARE
  auxItemID VARCHAR2(10);
BEGIN
  auxItemID := &ItemID_to_return;
  handleReturns_library(auxItemID);
END;

SELECT * FROM rent;
SELECT * FROM book;

--------------------------------------------------------------
-- let's use cursor 

-- PARTICULAR FUNCTION GET ALL DATE RETURN 
create or replace procedure All_Dat_Return(itemiDD varchar2)

is 
cursor all_return_book is
 
   select Return_date 
 from book join rent on Item_ID=ID
 where itemid like itemiDD ;
 
 cursor all_return_video is
   select Return_date 
 from video join rent on Item_ID=ID 
 where itemid like itemiDD ;
 
 B cBooks%ROWTYPE;
 V cVideos%ROWTYPE;
 
 BEGIN

  IF itemiDD IN (SELECT bookid FROM book )  THEN
  DBMS_OUTPUT.PUT_LINE('id   returnDate');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------');
   for B in all_return_book loop 
      DBMS_OUTPUT.PUT_LINE( itemiDD || '     ' || B.Return_date );
      EXIT WHEN cBooks%NOTFOUND;
    END LOOP;
     ELSIF itemiDD IN (SELECT videoid FROM video )  THEN
  DBMS_OUTPUT.PUT_LINE('id   returnDate');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------');
   for V in all_return_video loop 
      DBMS_OUTPUT.PUT_LINE( itemiDD || '     ' || B.Return_date );
      EXIT WHEN cVideos%NOTFOUND;
    END LOOP;
 
 -- type media does't exist
  ELSE
    DBMS_OUTPUT.PUT_LINE('TYPE INCORRECT, you must choose between books or videos');
  END IF;
END;

SET SERVEROUTPUT ON;
DECLARE
  ItemIDDD VARCHAR2(10);
BEGIN
  ItemIDDD := &ID_books_or_videos;
  All_Dat_Return(ItemIDDD);
END;

------------------------------------------------------------------------------
----- now affich all media 

CREATE OR REPLACE PROCEDURE allMedia_library(mediaType VARCHAR2)
IS
  CURSOR cBooks
  IS
    SELECT *
    FROM book;
  
  CURSOR cVideos
  IS
    SELECT *
    FROM video;
  
  B cBooks%ROWTYPE;
  V cVideos%ROWTYPE;
BEGIN
-----cursor for methode 1----------
  IF mediaType LIKE 'books' THEN
  DBMS_OUTPUT.PUT_LINE('ISBN     ID     STATE     AVALABILITY     DEBY_COST     LOST_COST    LOCATION');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------');
   for B in cBooks loop 
      DBMS_OUTPUT.PUT_LINE(B.isbn || '     ' || B.bookid || '     ' || B.state || '     ' || B.avalability || '     ' || B.debycost || '     ' ||
      B.lostcost || '     ' || B.address);
      
      EXIT WHEN cBooks%NOTFOUND;
    END LOOP;
    
-----cursor for methode 2------------
  ELSIF mediaType LIKE 'videos' THEN
    OPEN cVideos;
    DBMS_OUTPUT.PUT_LINE('TITLE     YEAR     ID     STATE     AVALABILITY     DEBY_COST     LOST_COST    LOCATION');
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------------------------');
    LOOP
      FETCH cVideos
      INTO V;
      EXIT WHEN cVideos%NOTFOUND;
      
      DBMS_OUTPUT.PUT_LINE(V.title || '     ' || V.year || '     ' || V.videoid || '     ' || V.state || '     ' || V.avalability || '     ' || V.debycost || '     ' ||
      V.lostcost || '     ' || V.address);
    END LOOP;
    
    
-- type media does't exist
  ELSE
    DBMS_OUTPUT.PUT_LINE('TYPE INCORRECT, you must choose between books or videos');
  END IF;
END;

SET SERVEROUTPUT ON;
DECLARE
  typeItem VARCHAR2(10);
BEGIN
  typeItem := &Select_between_books_or_videos;
  allMedia_library(typeItem);
END;


-------------------------------------------------
--when sysdate > :old.returndate then fines augment and statusCard=B
CREATE OR REPLACE TRIGGER modifyFines_library
AFTER DELETE
ON rent
FOR EACH ROW
DECLARE
  auxCardID NUMBER;
  auxItemID VARCHAR2(6);
  newCost NUMBER;
BEGIN  
  SELECT cardid, itemid INTO auxCardID, auxItemID
  FROM rent
  WHERE cardid LIKE :old.cardid;
  
  IF sysdate > :old.returndate THEN
  
    IF auxItemID in (select videoid from video) THEN 
    
      SELECT debyCost INTO newCost
      FROM video
      WHERE videoid LIKE auxItemID;
      
    ELSIF auxItemID in (select bookid from book) THEN
    
      SELECT debyCost INTO newCost
      FROM book
      WHERE bookid LIKE auxItemID;
      
    END IF;
    
    UPDATE card
    SET status = 'B', fines = (fines + newCost)
    WHERE cardid LIKE auxCardID;
  ELSE
    DBMS_OUTPUT.PUT_LINE('The item has been return before deadline');
  END IF;
END;


--------------------
--EXAMPLE --
INSERT INTO customer
VALUES (12,'ALEJANDRO','ZAIDIN',629629629,'alex123','al12',sysdate,112);

SELECT * FROM rent;

SET SERVEROUTPUT ON;
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

SELECT * FROM rent;

SET SERVEROUTPUT ON;
DECLARE
  auxItemID VARCHAR2(10);
BEGIN
  auxItemID := &ItemID_to_return;
  handleReturns_library(auxItemID);
END;

DELETE FROM card WHERE cardid LIKE 112;
SELECT * FROM card;


---------------------------------------------------------------------
--OBJECT--
CREATE OR REPLACE TYPE director_library AS OBJECT(
employeeid NUMBER,
name VARCHAR2(40),
address VARCHAR2(50),
phone INT(9),
paycheck NUMBER(10,2),
extrapaycheck NUMBER(10,2)
);

SET SERVEROUTPUT ON;
DECLARE 
   director director_library; 
BEGIN 
   director := director_library('212', 'CHANDLER', 'OUR HEARTHS', 688688688,1150.5,500); 
   dbms_output.put_line('DIRECTOR ID: '|| director.employeeid); 
   dbms_output.put_line('--------------------------------------------' ); 
   dbms_output.put_line('NAME: '|| director.name); 
   dbms_output.put_line('ADDRESS: '|| director.address); 
   dbms_output.put_line('PHONE: '|| director.phone); 
   dbms_output.put_line('PAYCHECK: '|| director.paycheck); 
   dbms_output.put_line('EXTRA: '|| director.extrapaycheck);
   dbms_output.put_line('--------------------------------------------' ); 
END;