/* (a) Construa um stored procedure que:
	- aceite o ssn de um funcionario
	- o remova da tabela  de  funcionarios,
	- remova  as  suas  entradas  da  tabela  works_on
	- remova  ainda  os  seus  dependentes.
	
Que  preocupacoes  adicionais  devem ter no storage procedure para alem das referidas anteriormente? */
-- Devemos ainda por a null os Mgr_ssn e Super_ssn caso estes sejam o Ssn que está a ser eliminado

go
alter procedure Company.uspDeleteEmp
	@empSsn char(9)
	as
		begin
			delete from Company.Works_on where Essn=@empSsn
			delete from Company.[Dependent] where  Essn=@empSsn
			update Company.Employee set Super_ssn=null where Super_ssn=@empSsn
			update Company.Department set Mgr_ssn=null where Mgr_ssn=@empSsn
			delete from Company.EMployee where Ssn=@empSsn
		end
go
exec Company.uspDeleteEmp '183623612'; -- testing procedure


/* (b) Crie um stored procedure que:
	- retorne um record-set com os funcionarios gestores de departamentos,
	- o ssn e numero de anos (como gestor) do funcionario mais antigo dessa lista. */
go
alter procedure Company.uspDeptManager
	@mgr_ssn char(9) output,
	@noOfYears int output
	as
		begin
			select Ssn, Fname, Minit, Lname, Bdate, [Address], Sex, Salary
			from Company.Department join Company.Employee on Mgr_ssn=Ssn

			select @mgr_ssn = Mgr_ssn, @noOfYears=max(DATEDIFF(year, Mgr_start_date, getdate()))
			from Company.Department
			where Mgr_ssn is not null
			group by Mgr_ssn, Mgr_start_date
			order by Mgr_start_date desc, Mgr_ssn asc
		end
go

/* testing procedure */
declare @ssn char(9)
declare @nYears int
exec Company.uspDeptManager @ssn output, @nYears output
print 'ssn -> ' + @ssn
print 'nYears -> ' + str(@nYears)


/* (c) Construa um trigger que:
	- nao permita que determinado funcionario seja definido como gestor de mais do que um departamento */
go
alter trigger Company.triggerMgr on Company.Department
after insert, update
as
	begin
		declare @ssn char(9);

		select @ssn=Mgr_ssn from inserted;

		if (exists (select * from Company.Department where Mgr_ssn=@ssn))
			begin
				raiserror ('Nao podes ser mgr de mais que um dept', 16,1);
				rollback tran;
			end
	end
go

/* testing trigger */
select * from Company.Department
select * from Company.Employee
update Company.Department set Mgr_Ssn='21312332 ' where Dnumber=5


/* (d) Crie um trigger que:
	- nao permita que determinado funcionario tenha um vencimento superior ao vencimento do gestor do seu departamento.
Nestes casos, o  trigger  deve  ajustar  o  salario  do  funcionario  para  um  valor  igual  ao  salario  do gestor menos uma unidade. */
go
create trigger Company.triggerDontEarnMore on Company.Employee
after insert, update
as
	begin
		declare @empSalary decimal(6,2);
		declare @ssn char(9);
		declare @dNumber int;

		select @empSalary=Salary, @ssn=Ssn, @dNumber=Dno from inserted;

		if (@empSalary > (	select Salary
							from Company.Employee join Company.Department on Ssn=Mgr_ssn
							where Dno = @dNumber))
			begin
				update Company.Employee set Salary = (select Salary
							from Company.Employee join Company.Department on Ssn=Mgr_ssn
							where Dno = @dNumber) - 1 where Ssn=@ssn
			end
	end
go

/* testing trigger */
insert into Company.Employee values ('Vasco', 'L', 'Ramos', 123445678, '1999-07-08', null, 'M', 1201 , null, 1);


/* (e) Crie uma UDF que, para determinado funcionario (ssn):
	- devolva o nome e localizacao dos projetos em que trabalha. */
go
alter function Company.EmpProjects (@ssn char(9)) returns table
as
	return (select Pname, Plocation
			from Company.Works_on join Company.Project on Pno=Pnumber
			where Essn=@ssn);
go

/* testing function */
select * from Company.EmpProjects ('342343434');


/* (f) Crie uma UDF que, para determinado departamento (dno):
	- retorne os funcionarios com um vencimento superior a media dos vencimentos desse departamento */
go
alter function Company.HighestPaidEmps (@dno int) returns table
as
	return (select *
			from Company.Employee
			where Dno=@dno and Salary > (	select avg(Salary)
											from Company.Employee
											where Dno=@dno)
			);
go

/* testing function */
select * from Company.HighestPaidEmps (2);


/* (g) Crie uma UDF que, para determinado departamento:
	- retorne um record-set com os projetos desse departamento.
Para cada projeto devemos ter um atributo com seu o orcamento mensal de mao de obra e outra coluna com o valor acumulado do orcamento. */
go
create function Company.employeeDeptHighAverage (@dNumber int) returns @ProjBudget Table
		(pName varchar(30), pnumber int not null, plocation varchar(15), dnum int, budget decimal, totalbudget decimal)
as
	begin
		declare @pName as varchar(30);
		declare @pnumber as int;
		declare @prevPnumber as int;
		declare @plocation as varchar(15);
		declare @dnum as int;
		declare @budget as decimal;
		declare @totalbudget as decimal;
		declare @hours as decimal;
		declare @salary as decimal;

		declare c cursor fast_forward
		for select Pname, Pnumber, Plocation, Dnum, [Hours], Salary
		from (Company.Project join Works_on on Pnumber=Pno) join Company.Employee on Essn=Ssn
		where Dnum=@dnumber;

		open c;

		fetch c into @pName, @pnumber, @plocation, @dnum, @hours, @salary;

		select @prevPnumber = @pnumber, @budget = 0, @totalbudget = 0;

		while @@fetch_status = 0
			begin
				if @prevPnumber <> @pnumber
					begin
						insert @ProjBudget values (@pName,@prevPnumber,@plocation,@dnum,@budget,@totalbudget);
						select @prevPnumber = @pnumber, @budget = 0;
					end

					set @budget += @salary*@hours/40;
					set @totalbudget += @salary*@hours/40;

					fetch c into @pName, @pnumber, @plocation, @dnum, @hours, @salary;
			end

		close c;
		deallocate c;

		return;
	end
go

/* testing function */
select * from Company.employeeDeptHighAverage (3);