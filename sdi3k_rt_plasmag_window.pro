pro sdi3k_rt_plasmag_window, widx, box, culz, pixmap=pixmap

    tries = 0
    catch, err_stat
    tries = tries + 1
    if err_stat ne 0 then wait, 0.5
    if tries gt 5 then goto, give_up
    restore, 'D:\SDI_Data\real_time_solar_wind\solwind_plasmag.IDL_sav'
    restore, 'D:\SDI_Data\magnetometer_realtime\magnetometer_realtime.IDL_sav'
    
    tvlct, r, g, b, /get

    window, widx, xsize=box[0], ysize=box[1], ypos=10, pixmap=pixmap
    erase, color=culz.white
    tnow   = dt_tm_tojs(systime())

    mc_npanel_plot,  layout, yinfo, /setup
    layout.position = [0.035, 0.055, 0.765, 0.935]
    layout.panels = 7
    layout.title  = ' '
    layout.xtitle = ' '
    layout.xrange = [tnow - 6.*3600., tnow + 900.]
    layout.erase = 0
    layout.color = culz.black
    layout.panel_rgb_background = {factor: 0.08, color: culz.orange, $
      hilite_factor: 0.18, hilite_color: culz.yellow, xhilite: [-999d, -999d]}
    layout.plot_panel_background = 0
    layout.charscale = 0.7
    layout.charthick=3
    layout.ypad(0:6) = fltarr(7) + 0.005
    layout.ypad(2) = 0.015


    yinfo.title = '!CIMF Bz [nT]'
    yinfo.charsize = 1.
    yinfo.style = 1
    yinfo.thickness = 3
    yinfo.symbol_color = culz.red
    yinfo.line_color = culz.red
    yinfo.symsize = 0.005
    yinfo.psym = 2
    yinfo.range = [-17., 17.]
    if max(abs(median(solmag.bz, 5))) gt 16. then yinfo.range = [-33., 33.]
    if max(abs(median(solmag.bz, 5))) gt 31. then yinfo.range = [-53., 53.]
    yinfo.zero_line = 0.00000001
    layout.top_axis = 1
    yinfo.right_ticks = 1
    yinfo.right_axis = 1

    mc_npanel_plot,  layout, yinfo, solmag.time, solmag.bz, panel=0, /time_axis, /plot_panel_background
    yinfo.title = ' '
    yinfo.right_axis = 0
    yinfo.rename_ticks = 1
    mc_npanel_plot,  layout, yinfo, solmag.time, solmag.bz, panel=0, /time_axis, /plot_panel_background
    yinfo.right_axis = 1
    yinfo.rename_ticks = 0
    oplot, [tnow, tnow], yinfo.range, thick=1, color=culz.bground, linestyle=2

    yinfo.symbol_color = culz.blue
    yinfo.line_color = culz.blue
    yinfo.title = '!CSolar Wind!C !CSpeed [km s!U-1!N]'
    yinfo.range = [270., 590.]
    if max(solplas.speed) gt 580 then yinfo.range[1] = 790.
    if max(solplas.speed) gt 780 then yinfo.range[1] = 990.
    mc_npanel_plot,  layout, yinfo, solplas.time, solplas.speed, panel=1, /time_axis, /plot_panel_background
    yinfo.title = ' '
    yinfo.right_axis = 0
    yinfo.rename_ticks = 1
    mc_npanel_plot,  layout, yinfo, solplas.time, solplas.speed, panel=1, /time_axis, /plot_panel_background
    yinfo.right_axis = 1
    yinfo.rename_ticks = 0
    oplot, [tnow, tnow], yinfo.range, thick=1, color=culz.bground, linestyle=2

    yinfo.symbol_color = culz.olive
    yinfo.line_color = culz.olive
    yinfo.title = '!CSolar Wind!C !CDensity [cm!U-1!N]'
    yinfo.range = [-3., 33.]
    if max(solplas.den) gt 30. then yinfo.range[1] = 63.
    if max(solplas.den) gt 60. then yinfo.range[1] = 93.
    mc_npanel_plot,  layout, yinfo, solplas.time, solplas.den, panel=2, /time_axis, /plot_panel_background
    yinfo.title = ' '
    yinfo.right_axis = 0
    yinfo.rename_ticks = 1
    mc_npanel_plot,  layout, yinfo, solplas.time, solplas.den, panel=2, /time_axis, /plot_panel_background
    yinfo.right_axis = 1
    yinfo.rename_ticks = 0
    oplot, [tnow, tnow], yinfo.range, thick=1, color=culz.bground, linestyle=2
    
    layout.top_axis = 0
    layout.panel_rgb_background = {factor: 0.09, color: culz.green, $
      hilite_factor: 0.18, hilite_color: culz.yellow, xhilite: [-999d, -999d]}
   
    yinfo.symbol_color = culz.black
    yinfo.line_color = culz.black
;    magsites = ['kaktovik', 'toolik', 'fortyukon', 'poker']
magsites = ['toolik', 'poker', 'gakona', 'kenai']
    for j=0,n_elements(magsites) - 1 do begin
        these = where(mag_data.site eq magsites[j], nmag)
        if nmag gt 0 then begin
           yinfo.title = strupcase(magsites[j]) + '!C !CMag H [nT]'
           times = mag_data[these].time
           valz  = mag_data[these].H
           valz  = valz - median(valz)
           ttuse = where(times gt (tnow - 6.*3600.), nuse)
;----------Do some crude auto-scaling:     
    
           yinfo.range = [-590., 240.]
           if nuse gt 0 then begin
              if min(valz[ttuse]) lt -590.  then yinfo.range[0] = -1090.
              if min(valz[ttuse]) lt -1090. then yinfo.range[0] = -1590.
              if max(valz[ttuse]) gt  240.  then yinfo.range[1] = 440.
              if max(valz[ttuse]) gt  440.  then yinfo.range[1] = 640.
           endif 
           mc_npanel_plot,  layout, yinfo, times, valz, panel = j + 3, /time_axis, /plot_panel_background
           yinfo.title = ' '
           yinfo.right_axis = 0
           yinfo.rename_ticks = 1
           mc_npanel_plot,  layout, yinfo, times, valz, panel = j + 3, /time_axis, /plot_panel_background
           yinfo.right_axis = 1
           yinfo.rename_ticks = 0
    oplot, [tnow, tnow], yinfo.range, thick=1, color=culz.bground, linestyle=2
        endif
    endfor

give_up:    
end