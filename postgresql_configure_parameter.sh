SELECT name AS parameter,
 (context IN ('user', 'superuser', 'backend', 'sighup', 'postmaster')) AS can_be_changed,
 (context = 'postmaster') AS change_requires_restart,
 (context = 'sighup') AS can_be_changed_by_reload
FROM pg_settings
ORDER BY name;

1. Parameter: The name of the configuration parameter.

2. can_be_changed: This column shows whether the parameter can be changed without a restart. It's true (`t`) if the parameter's context allows changes at runtime (i.e., `user`, `superuser`, `backend`, `sighup`, or `postmaster`).

3. change_requires_restart: This column indicates whether changing the parameter requires a PostgreSQL service restart, which is true (`t`) if the context is `postmaster`.

4. can_be_changed_by_reload: This column shows whether the parameter can be changed by reloading the configuration file (`postgresql.conf`), which is true (`t`) if the context is `sighup`.
