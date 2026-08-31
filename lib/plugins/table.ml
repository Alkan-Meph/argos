let plugins =
  [
    ("dns", Dns.load_from_config);
    ("logger", Logger.load_from_config);
    ("mem", Mem.load_from_config);
    ("db", Db.load_from_config);
  ]
