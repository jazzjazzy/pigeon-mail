{application,rest_pastebin,
             [{description,"Cowboy REST Pastebin example inspired by sprunge."},
              {vsn,"1"},
              {modules,[]},
              {registered,[rest_pastebin_sup]},
              {applications,[cowboy,kernel,stdlib]},
              {mod,{rest_pastebin_app,[]}},
              {env,[]}]}.
