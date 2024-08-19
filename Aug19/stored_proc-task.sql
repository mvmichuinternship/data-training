/*create database data_training_db;*/


/*CREATE TABLE src_employees (
    id INT PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE tgt_employees (
    id INT PRIMARY KEY,
    name VARCHAR(255),
	is_deleted BIT DEFAULT 0,
    deleted_at DATETIME NULL,
);*/

ALTER TABLE tgt_employees
DROP CONSTRAINT PK__tgt_empl__3213E83F916EED1E;

go

ALTER PROCEDURE EmployeeDataSync

AS
BEGIN
	INSERT INTO tgt_employees (id, name, is_deleted, deleted_at)
    SELECT s.id, s.name, 0, NULL
    FROM src_employees s
    LEFT JOIN tgt_employees t on s.id = t.id AND t.is_deleted = 0
    WHERE t.id IS NULL;

	UPDATE tgt_employees
    SET is_deleted = 1,
        deleted_at = GETDATE()
    WHERE id NOT IN (SELECT id FROM src_employees)
    and is_deleted = 0;

	WITH Updated AS (
        SELECT s.id, s.name
        FROM src_employees s
        INNER JOIN tgt_employees t ON s.id = t.id
        WHERE t.is_deleted = 0
    )
    INSERT INTO tgt_employees (id, name, is_deleted, deleted_at)
    SELECT u.id, u.name, 0, NULL
    FROM Updated u
    LEFT JOIN tgt_employees t ON u.id = t.id AND t.is_deleted = 0
    GROUP BY u.id, u.name;
	WITH RankedEmployees AS (
        SELECT id, name, 
               ROW_NUMBER() OVER (PARTITION BY id ORDER BY id DESC) AS rn
        FROM tgt_employees
        WHERE is_deleted = 0
    )
    SELECT id, name, rn
    FROM RankedEmployees
    WHERE rn = 1
end
go

EXECUTE EmployeeDataSync


INSERT INTO src_employees (id, name) 
VALUES 
    (1, 'mv'),
    (2, 'vk'),
    (3, 'mk');
    
UPDATE src_employees
SET name = 'vkk'
WHERE id = 2;

DELETE FROM src_employees
WHERE id = 3;

select * from tgt_employees;