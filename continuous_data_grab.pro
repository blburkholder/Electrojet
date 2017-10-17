pro continuous_data_grab
  
  big_t = []
  big_s = []
  big_H = []
  big_D = []
  big_Z = []
  
  for i = 1,1000 do begin
    get_realtime_alaskan_magnetometer_data
    infile = '/home/computation/Documents/Classes/Aeronomy/Electrojet/magnetometer_realtime.csv'
    mag_in = read_csv(infile)
  
    site = mag_in.FIELD1
    time = mag_in.FIELD2
    H = mag_in.FIELD3
    D = mag_in.FIELD4
    Z = mag_in.FIELD5
  
    ;600 seconds is 10 mins or 20 data points at 30 second cadence
    permitted_gap_size = 600
 
    magsites = ['toolik', 'poker', 'gakona','kenai']   
    site_file_count = [0,0,0,0]
    for j=0,n_elements(magsites) - 1 do begin 
      p = where(site eq magsites[j],cp)
      t = time(p)
      hh = H(p)
      dd = D(p)
      zz = Z(p)
      sites = site(p)
      print, magsites[j]
      ;look through the data to find any gaps
      f = where((t(1:cp-1) - t(0:cp-2)) gt permitted_gap_size,gap_count)
      if gap_count eq 1 then begin 
        ;use the data gaps as one way to break into files
        big_t = [big_t,t(0:f)]
        big_s = [big_s,sites(0:f)]
        big_H = [big_H,hh(0:f)]
        big_D = [big_D,dd(0:f)]
        big_Z = [big_Z,zz(0:f)]

        site_file_count(j) = site_file_count(j)+1
        magg_data = create_struct('site',big_s,'time',big_t,'H',big_H,'D',big_D,'Z',big_Z)      
        write_csv, '/home/computation/Documents/Classes/Aeronomy/Electrojet/magnetometer'+magsites[j]+strtrim(site_file_count(j),2)+'.csv', magg_data
        
        big_t = t(f+1:-1)
        big_s = sites(f+1:-1)
        big_H = hh(f+1:-1)
        big_D = dd(f+1:-1)
        big_Z = zz(f+1:-1)
      endif else if gap_count eq 0 then begin
        big_t = [big_t,t]
        big_s = [big_s,sites]
        big_H = [big_H,hh]
        big_D = [big_D,dd]
        big_Z = [big_Z,zz]
        if i MOD 10 eq 0 then begin
          ;make a file out of 5 days consecutive data
          site_file_count(j) = site_file_count(j)+1
          magg_data = create_struct('site',big_s,'time',big_t,'H',big_H,'D',big_D,'Z',big_Z)
          write_csv, '/home/computation/Documents/Classes/Aeronomy/Electrojet/magnetometer'+magsites[j]+strtrim(site_file_count(j),2)+'.csv', magg_data
        endif
      endif
    endfor
  wait, 43200
  endfor  
 end
  