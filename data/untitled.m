

EEG=pop_biosig('f_LUI14071945017.EDF','rmeventchan','off');
EEG=pop_chanevent(EEG,22,'duration','on','edge','leading');