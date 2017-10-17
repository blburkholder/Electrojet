pro get_baseline
  magsites = ['toolik', 'poker', 'gakona','kenai']
  min_stds_H = [5000,5000,5000,5000]
  min_stds_D = [5000,5000,5000,5000]
  min_stds_Z = [5000,5000,5000,5000]
  base_H = [0,0,0,0]
  base_D = [0,0,0,0]
  base_Z = [0,0,0,0]
  ;loop over 4 stations
  for j=0,n_elements(magsites) - 1 do begin
    stdH_l = 5000
    stdD_l = 5000
    stdZ_l = 5000
    Hb_l = 0
    Db_l = 0
    Zb_l = 0
    ;loop over all possible files per station
    for i = 1,1000 do begin
      infile = '/home/computation/Documents/Classes/Aeronomy/Electrojet/magnetometer'+magsites[j]+strtrim(i,2)+'.csv'
      if file_test(infile) eq 1 then begin
        ;quit once we have gone past last available file for this station
        mag_in = read_csv(infile)
      endif else break
    
      ;all the data from a given file
      site = mag_in.FIELD1
      time = mag_in.FIELD2
      H = mag_in.FIELD3
      D = mag_in.FIELD4
      Z = mag_in.FIELD5  
  
      ;number of points in the file
      n = size(site)
      n = n(1)
 
      ;data is 30 second cadence
      ;window length 6 hours?
      w = 60*12
      ;slide length 30 mins?
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
            D2 = D[(k-1)*s:(k-1)*s+w-1]
            Z2 = Z[(k-1)*s:(k-1)*s+w-1]
            stdH = STDDEV(H2)
            stdD = STDDEV(D2)
            stdZ = STDDEV(Z2) 
            Hbase = mean(H2)
            Dbase = mean(D2)
            Zbase = mean(Z2)
          ;then its takes a whole window length
          ;from the last point inwards
          endif else begin
            stdH = STDDEV(H[n-w:n-1])
            stdD = STDDEV(D[n-w:n-1])
            stdZ = STDDEV(Z[n-w:n-1])
            Hbase = mean(H[n-w:n-1])
            Dbase = mean(D[n-w:n-1])
            Zbase = mean(Z[n-w:n-1])
          endelse
          ;in each window, see if the std is lower than all previous
          if stdH lt stdH_l then begin
            stdH_l = stdH
            Hb_l = Hbase;
          endif  
          if stdD lt stdD_l then begin
            stdD_l = stdD
            Db_l = Dbase;
          endif
          if stdZ lt stdZ_l then begin
            stdZ_l = stdZ
            Zb_l = Zbase;
          endif   
        endfor    
      endif
    endfor
    ;after gone through all files, save lowest std
    ;and the baseline per component per station 
    if stdH_l lt min_stds_H(j) then begin
      min_stds_H(j) = stdH_l
      base_H(j) = Hb_l
    endif
    if stdD_l lt min_stds_D(j) then begin
      min_stds_D(j) = stdD_l
      base_D(j) = Db_l
    endif
    if stdZ_l lt min_stds_Z(j) then begin
      min_stds_Z(j) = stdZ_l
      base_Z(j) = Zb_l
    endif
  endfor
end