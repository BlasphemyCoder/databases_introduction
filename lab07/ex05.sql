/* (a.i) Vista com nome dos titulos e nome dos respetivos autores */
go
create view Titles_Authors (Title, Author_name) as
	select Title, CONCAT(au_fname,' ',au_lname)
	from titles join titleauthor on titles.title_id=titleauthor.title_id
			join authors on titleauthor.au_id=authors.au_id;
go

/* (a.ii) Vista com nome dos editores e nome dos respetivos funcionarios */
go
create view Pubs_Emps as
	select pub_name, fname, lname
	from publishers join employee on publishers.pub_id=employee.pub_id;
go

/* (a.iii) Vista com nome das lojas e nome dos t�tulos vendidos nessa loja */
go
create view Stores_Books as
	select stor_name, title
	from titles join sales on titles.title_id=sales.title_id
			join stores on sales.stor_id=stores.stor_id;
go

/* (a.iv) Vista com nome e id dos livros do tipo 'Business' */
go
create view business_books as
	select title_id, title, [type], pub_id, price, notes
	from titles
	where type='business'
	with check option;
go

/* (b.i) Selecionar os autores dos livros 'Is Anger the Enemy?' e 'Sushi, Anyone?' */
select Title, Author_name
from Titles_Authors
where title in ('Is Anger the Enemy?', 'Sushi, Anyone?');

/* (b.ii) Selecionar os funcionarios da editora 'Algodata Infosystems' */
select fname, lname
from Pubs_Emps
where pub_name='Algodata Infosystems';

/* (b.iii) Selecionar lojas que venderam o titulo 'Is Anger the Enemy?' */
select stor_name
from Stores_Books
where title='Is Anger the Enemy?';

/* (b.iv) Selecionar todos os livros do tipo 'Business' */
select *
from business_books;

/* (d) */
insert into Business_Books(title_id, title, [type], pub_id, price, notes) values('BDDDD1', 'New BD Book', 'popular_comp', '1389', $30.00, 'A must-read for DB course.');

-- (d.i) The check option ( where type='business' ) is not respected so teh insert is not successful

-- (d.ii & d.iii) The solution is to remove the command 'with check option' from the view definition  