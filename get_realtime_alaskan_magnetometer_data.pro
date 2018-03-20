pro get_realtime_alaskan_magnetometer_data, folder
    a_rec    = {site: 'unknown', time: 0D, H: 0., D: 0., Z: 0.} 
    magsites = ['toolik','poker','eagle','gakona','kenai','trapper','kaktovik','ftyukon']
    for j=0,n_elements(magsites) - 1 do begin 
      outfile = folder+'latest_' + magsites[j] + '.csv'
      oUrl = OBJ_NEW('IDLnetUrl')
      oUrl->SetProperty, url_scheme = 'http'
      oUrl->SetProperty, url_host = 'magnetometer.rcs.alaska.edu'
      site = magsites[j]
      oUrl->SetProperty, URL_PATH = '/REALTIME/' + site + '_12.csv'
      attempts = 0
      
      ;if station goes down, try to regrab the data
      ;every minute for 5 minutes, if this fails
      ;then screw it
      CATCH, Error_status
      IF Error_status NE 0 AND attempts lt 5 THEN BEGIN
        attempts = attempts + 1
        PRINT, 'waiting '+magsites[j], attempts
        
        wait, 30
        fn = oUrl->Get(FILENAME = outfile )

      ENDIF ELSE IF Error_status NE 0 THEN BEGIN
        CATCH, /CANCEL
        print, 'failure'+TIMESTAMP()
        outfile = 'squid'
        GOTO, JUMP1
      ENDIF

      fn = oUrl->Get(FILENAME = outfile )
      JUMP1: 

      OBJ_DESTROY, oUrl
      
      if file_test(outfile) then begin
         mag_in = read_csv(outfile)
         rcd = n_elements(mag_data) 
         if rcd eq 0 then begin
            mag_data = replicate(a_rec, n_elements(mag_in.field1)) 
         endif else begin
            mag_data = [mag_data, replicate(a_rec, n_elements(mag_in.field1))]
         endelse
         
         iy = long(mag_in.field1)
         im = long(mag_in.field2)
         id = long(mag_in.field3)
         jd = 367*iy-7*(iy+(im+9)/12)/4-3*((iy+(im-9)/7)/100+1)/4 $
           +275*im/9+id+1721029
         
         ;i just extracted the calculations from ymds2js
         times = (3600.*mag_in.field4 + 60.*mag_in.field5 + mag_in.field6) + (jd-2451545)*86400d0
         
         mag_data[rcd:*].site = magsites[j]
         mag_data[rcd:*].time = times
         mag_data[rcd:*].H = mag_in.field7
         mag_data[rcd:*].D = mag_in.field8
         mag_data[rcd:*].Z = mag_in.field9
      endif
    endfor
    write_csv, folder+'magnetometer_realtime.csv', mag_data
end
