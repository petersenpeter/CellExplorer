---
layout: default
title: Setup access
parent: Public data
nav_order: 3
---
# Setup database access
{: .no_toc}
To have full access to the [Buzsaki lab databank](https://buzsakilab.com/wp/database/) with CellExplorer, there are two necessary steps you have to do in Matlab: add your credentials and define the repository paths. Public reference data can still be used without credentials. This page is therefore mostly dedicated to lab members.

### 1. Add your db credentials
Once CellExplorer has been added to your Matlab Set Path, you should provide your buzsakilab.com credentials in the file [db_credentials.m](https://github.com/petersenpeter/CellExplorer/blob/master/db/db_credentials.m). In the Matlab Command Window type:
```m
edit db_credentials.m
```
In the credentials file, replace the two lines below with your credentials:
```m
credentials.username = 'user';
credentials.password = 'password';
```
### 2. Define paths to data repositories
Paths are generated from the [repository](https://buzsakilab.com/wp/repositories/) definition in the database. Here you need to define the root path for each repository in [db_local_repositories.m](https://github.com/petersenpeter/CellExplorer/blob/master/db/db_local_repositories.m). To use the NYUshare_Datasets (the NYU share dataset directory), you must define the system path to the repository, e.g.:

```m
repositories.NYUshare_Datasets = '/Volumes/buzsakilab/Buzsakilabspace/Datasets';
```
Likewise to link to data located in NYUshare_Peter, provide the system path to the repository:
```m
repositories.NYUshare_Peter = '/Volumes/buzsakilab/peterp03/IntanData';
```
This system allows you to define paths that are specific to each computer-system and separates system-access from the data storage solution, which could be a local drive hard drive, a centralized network storage, or another storage solutions.

### 3. Test db connection
Now you can test the connection by typing:
```m
sessionTest = 'Peter_MS10_170307_154746_concat';
sessions = db_load_sessions('sessionName',sessionTest);
session = sessions{1};
```
If succesfull it will create the session struct in your workspace containing metadata for that session. You can learn more about the data structure and format [here]({{"/datastructure/data-structure-and-format/"|absolute_url}}).

There are a couple of database example calls in the Matlab script [db_example.m](https://github.com/petersenpeter/CellExplorer/blob/master/db/db_example.m) located in the db folder.
