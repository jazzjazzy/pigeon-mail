{application,echo_post,
             [{description,"Cowboy POST echo example."},
              {vsn,"1"},
              {modules,[]},
              {registered,[echo_post_sup]},
              {applications,[cowboy,kernel,stdlib]},
              {mod,{echo_post_app,[]}},
              {env,[]}]}.
