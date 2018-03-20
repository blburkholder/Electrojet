function get_baseline
  magsites = ['toolik','poker','eagle','gakona','kenai','trapper','kaktovik','ftyukon']
  base_pathpath = '/home/computation/Documents/Classes/Aeronomy/Electrojet2/baseline/'
  data_pathpath = '/home/computation/Documents/Classes/Aeronomy/Electrojet2/data_grab/'
  n = n_elements(magsites)

  if not file_test(base_pathpath+'stds_H.csv') then begin
    min_stds_H = make_array(n,1, /DOUBLE, VALUE = 50000.0)
    min_stds_Z = make_array(n,1, /DOUBLE, VALUE = 50000.0)
    base_H = make_array(n,1, /DOUBLE)
    base_Z = make_array(n,1, /DOUBLE)

    write_csv, base_pathpath+'stds_H.csv', min_stds_H
    write_csv, base_pathpath+'stds_Z.csv', min_stds_Z
    write_csv, base_pathpath+'bases_H.csv', base_H
    write_csv, base_pathpath+'bases_Z.csv', base_Z
  endif 

  min_stds_H = read_csv(base_pathpath+'stds_H.csv')
  min_stds_Z = read_csv(base_pathpath+'stds_Z.csv')
  base_H = read_csv(base_pathpath+'bases_H.csv')
  base_Z = read_csv(base_pathpath+'bases_Z.csv') 
  
  min_stds_H = min_stds_H.FIELD1  
  min_stds_Z = min_stds_Z.FIELD1  
  base_H = base_H.FIELD1
  base_Z = base_Z.FIELD1  
  
  for j = 0,n_elements(magsites) - 1 do begin
    stdH_l = 50000.0
    stdZ_l = 50000.0
    Hb_l = 0.0
    Zb_l = 0.0
    
    infile1 = data_pathpath+magsites(j)+strtrim(1,2)+'.csv'
    infile2 = data_pathpath+magsites(j)+strtrim(2,2)+'.csv'
    if file_test(infile1) eq 1 then begin
      mag_in1 = read_csv(infile1)
    endif else begin
      mag_in1 = []
    endelse
    if file_test(infile2) eq 1 then begin 
      mag_in2 = read_csv(infile2)
    endif else begin
      mag_in2 = []
    endelse
    
    ;combine data from 2 files that get continuously
    ;updated from continuous_data_grab
    if n_elements(mag_in2) gt 0 then begin
      site = [mag_in1.FIELD1,mag_in2.FIELD1]
      time = [mag_in1.FIELD2,mag_in2.FIELD2]
      H = [mag_in1.FIELD3,mag_in2.FIELD3]
      Z = [mag_in1.FIELD4,mag_in1.FIELD4] 
    endif else begin 
      site = mag_in1.FIELD1
      time = mag_in1.FIELD2
      H = mag_in1.FIELD3
      Z = mag_in1.FIELD4
    endelse 
  
    n = n_elements(site)
     
    ;data is 30 second cadence
    ;window length 12 hours?
    ;w = (hours)*(60 min/hr)*(2 points/min)
    ;note - Eagle has different resolution
    w = 12*60*2
    ;slide length 30 mins (60 points)?
    s = 60
    ;make sure file length is larger than window
    if w < n+1 then begin
      l = 1 + FLOOR((n-w)/s)
      ;loop over number of windows
      for k = 1,l+1 do begin
        ;the window slides all the way down
        ;until there arent enough points to
        ;fill the whole window
        if k lt l+1 then begin
          H2 = H[(k-1)*s:(k-1)*s+w-1]
          Z2 = Z[(k-1)*s:(k-1)*s+w-1]
          stdH = STDDEV(H2)
          stdZ = STDDEV(Z2) 
          Hbase = median(H2)
          Zbase = median(Z2)
        ;then its takes a whole window length
        ;from the last point inwards
        endif else begin
          stdH = STDDEV(H[n-w:n-1])
          stdZ = STDDEV(Z[n-w:n-1])
          Hbase = median(H[n-w:n-1])
          Zbase = median(Z[n-w:n-1])
        endelse
        ;in each window, see if the std is lower than all previous
        if stdH lt stdH_l then begin
          stdH_l = stdH
          Hb_l = Hbase;
        endif  
        if stdZ lt stdZ_l then begin
          stdZ_l = stdZ
          Zb_l = Zbase;
        endif   
      endfor   
    endif
    ;after gone through all files, save lowest std
    ;and the baseline per component per station 
    if stdH_l lt min_stds_H(j) then begin
      min_stds_H(j) = stdH_l
      base_H(j) = Hb_l
    endif
    if stdZ_l lt min_stds_Z(j) then begin
      min_stds_Z(j) = stdZ_l
      base_Z(j) = Zb_l
    endif
  endfor

  write_csv, base_pathpath+'stds_H.csv', min_stds_H
  write_csv, base_pathpath+'stds_Z.csv', min_stds_Z
  write_csv, base_pathpath+'bases_H.csv', base_H
  write_csv, base_pathpath+'bases_Z.csv', base_Z
      
  bases = [[base_H],$
          [base_Z]]
  return, bases
end
