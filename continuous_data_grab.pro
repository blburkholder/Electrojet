;task schedule this to run every 10 hours
pro continuous_data_grab

  magsites = ['toolik', 'poker','eagle','gakona','kenai','trapper','kaktovik','ftyukon']
  pathpath = '/home/computation/Documents/Classes/Aeronomy/Electrojet2/data_grab/'

  ;get current 12 hours data from internet
  get_realtime_alaskan_magnetometer_data, pathpath
  infile = pathpath+'magnetometer_realtime.csv'
  mag_in = read_csv(infile)
  
  site = mag_in.FIELD1
  time = mag_in.FIELD2
  H = mag_in.FIELD3
  Z = mag_in.FIELD5

  ;for first time task scheduler grabs data
  if not file_test(pathpath+'one_or_two.csv') then begin
    write_csv, pathpath+'one_or_two.csv', 1
  endif

  oot = read_csv(pathpath+'one_or_two.csv')
  oot = oot.FIELD1

  for j = 0,n_elements(magsites) - 1 do begin
    p = where(site eq magsites[j],cp)
    t = time(p)
    hh = H(p)
    zz = Z(p)
    sites = site(p)

    now = create_struct('site',sites,'time',t,'H',hh,'Z',zz)

    ;only care about stations with successful grab from internet
    if cp ne 0 then begin

     ;this block is for first 2 times the task scheduler grabs data
      if not file_test(pathpath+magsites(j)+strtrim(1,2)+'.csv') then begin
        print, 1
        write_csv, pathpath+magsites(j)+strtrim(1,2)+'.csv', now
      endif else if not file_test(pathpath+magsites(j)+strtrim(2,2)+'.csv') then begin
        print, 2
        tthen = read_csv(pathpath+magsites(j)+strtrim(1,2)+'.csv')
	      ;dont save overlapping data
        hgg = where(tthen.FIELD2 eq t(0))
        print, hgg
        if hgg eq -1 then begin
      	  write_csv, pathpath+magsites(j)+strtrim(2,2)+'.csv', now
	      endif else begin
	        now = create_struct('site',sites(n_elements(t)-1-hgg:-1),$
	          'time',t(n_elements(t)-1-hgg:-1),'H',hh(n_elements(t)-1-hgg:-1),$
	          'Z',zz(n_elements(t)-1-hgg:-1))
	        write_csv, pathpath+magsites(j)+strtrim(2,2)+'.csv', now
	      endelse
	  
      ;this block for after first 2 times
      endif else if oot eq 1 then begin
        tthen = read_csv(pathpath+magsites(j)+strtrim(1,2)+'.csv')
        hgg = where(tthen.FIELD2 eq t(0))
        if hgg eq -1 then begin
	        write_csv, pathpath+magsites(j)+strtrim(2,2)+'.csv', now
	      endif else begin
	        now = create_struct('site',sites(n_elements(t)-1-hgg:-1),$
	          'time',t(n_elements(t)-1-hgg:-1),'H',hh(n_elements(t)-1-hgg:-1),$
	          'Z',zz(n_elements(t)-1-hgg:-1))
	        write_csv, pathpath+magsites(j)+strtrim(2,2)+'.csv', now
	      endelse
      endif else begin
        tthen = read_csv(pathpath+magsites(j)+strtrim(2,2)+'.csv')
        hgg = where(tthen.FIELD2 eq t(0))
        if hgg eq -1 then begin
	        write_csv, pathpath+magsites(j)+strtrim(1,2)+'.csv', now
	      endif else begin
	        now = create_struct('site',sites(n_elements(t)-1-hgg:-1),$
	          'time',t(n_elements(t)-1-hgg:-1),'H',hh(n_elements(t)-1-hgg:-1),$
	          'Z',zz(n_elements(t)-1-hgg:-1))
	        write_csv, pathpath+magsites(j)+strtrim(1,2)+'.csv', now
	      endelse
      endelse
    endif
  endfor

  ;only keeping 2 files (20 hours) worth of data
  ;get baseline compares with a longer history
  if oot eq 1 then begin
    oot = 2
  endif else begin
    oot = 1
  endelse
  write_csv, pathpath+'one_or_two.csv', oot
end
