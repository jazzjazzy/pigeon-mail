{application,echo_get,
             [{description,"Cowboy GET echo example."},
              {vsn,"1"},
              {modules,[]},
              {registered,[echo_get_sup]},
              {applications,[cowboy,kernel,stdlib]},
              {mod,{echo_get_app,[]}},
              {env,[]}]}.
