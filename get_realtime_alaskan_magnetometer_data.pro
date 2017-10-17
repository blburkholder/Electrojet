pro RT_get_mag_site, site, outfile
    sts = 0
    catch, sts
    if sts ne 0 then return
    outfile = '/home/computation/Documents/Classes/Aeronomy/Electrojet/latest_' + site + '.csv'
    oUrl = OBJ_NEW('IDLnetUrl')
    oUrl->SetProperty, url_scheme = 'https'
    oUrl->SetProperty, url_host = 'www.asf.alaska.edu'
    oUrl->SetProperty, URL_PATH = '/magnet/realtime_csv_file/' + site + '/12'
    fn = oUrl->Get(FILENAME = outfile )
    OBJ_DESTROY, oUrl
end

;    KAK    <kaktovik>
;    TOO    <toolik>
;    FYU    <fortyukon>
;    PKR    <poker>
;    CGO    <cigo>
;    EAA    <eagle>
;    TRC    <trapper>
;    GAK    <gakona>
;    KEN    <kenai>

pro get_realtime_alaskan_magnetometer_data

    a_rec    = {site: 'unknown', time: 0D, H: 0., D: 0., Z: 0.} 
    magsites = ['kaktovik', 'toolik', 'fortyukon', 'cigo', 'poker', 'gakona','kenai']   
    for j=0,n_elements(magsites) - 1 do begin 
        RT_get_mag_site, magsites[j], outfile
        if file_test(outfile) then begin
           mag_in = read_csv(outfile)
           rcd    = n_elements(mag_data) 
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
           ;times = ymds2js(mag_in.field1, mag_in.field2, mag_in.field3, 3600.*mag_in.field4 + 60.*mag_in.field5 + mag_in.field6)
           
           mag_data[rcd:*].site = magsites[j]
           mag_data[rcd:*].time = times
           mag_data[rcd:*].H    = mag_in.field7
           mag_data[rcd:*].D    = mag_in.field8
           mag_data[rcd:*].Z    = mag_in.field9
        endif
    endfor
    write_csv, '/home/computation/Documents/Classes/Aeronomy/Electrojet/magnetometer_realtime.csv', mag_data
end
