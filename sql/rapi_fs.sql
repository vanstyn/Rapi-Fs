
DROP TABLE IF EXISTS [realm];
CREATE TABLE [realm] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [name] varchar(64) NOT NULL,
  [driver_class] varchar(64) NOT NULL DEFAULT 'Filesystem',
  [args] varchar(255) DEFAULT NULL,
  [extra] text DEFAULT NULL,
  UNIQUE ([name])
);


DROP TABLE IF EXISTS [directory];
CREATE TABLE [directory] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [realm_id] INTEGER NOT NULL,
  [pid] INTEGER DEFAULT NULL,
  [name] varchar(255) NOT NULL,
  
  [sync_ts] datetime NOT NULL,
  [check_val] varchar(255) NOT NULL,
  
  [mtime] INTEGER NOT NULL,
  [ctime] INTEGER NOT NULL,
  
  FOREIGN KEY ([realm_id]) REFERENCES [realm] ([id]) 
   ON DELETE RESTRICT ON UPDATE RESTRICT,
  
  FOREIGN KEY ([pid]) REFERENCES [directory] ([id]) 
   ON DELETE CASCADE ON UPDATE CASCADE
);


DROP TABLE IF EXISTS [file];
CREATE TABLE [file] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [realm_id] INTEGER NOT NULL,
  [did] INTEGER DEFAULT NULL,
  [name] varchar(255) NOT NULL,
  
  [sync_ts] datetime NOT NULL,
  [check_val] varchar(255) NOT NULL,
  
  [mtime] INTEGER NOT NULL,
  [ctime] INTEGER NOT NULL,
  
  [bytes] INTEGER NOT NULL,
  
  
  FOREIGN KEY ([realm_id]) REFERENCES [realm] ([id]) 
   ON DELETE RESTRICT ON UPDATE RESTRICT,
  
  FOREIGN KEY ([did]) REFERENCES [directory] ([id]) 
   ON DELETE CASCADE ON UPDATE CASCADE
);


DROP TABLE IF EXISTS [file_meta];
CREATE TABLE [file_meta] (
  [id] INTEGER PRIMARY KEY NOT NULL,
  [realm_id] INTEGER NOT NULL,

  FOREIGN KEY ([realm_id]) REFERENCES [realm] ([id]) 
   ON DELETE RESTRICT ON UPDATE RESTRICT,

  FOREIGN KEY ([id]) REFERENCES [file] ([id]) 
   ON DELETE CASCADE ON UPDATE CASCADE
);



