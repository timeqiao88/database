CREATE OR REPLACE FUNCTION audit.log_current_action() RETURNS trigger AS $body$
DECLARE
    v_old_data TEXT;
    v_new_data TEXT;
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        v_old_data := ROW(OLD.*);
        v_new_data := ROW(NEW.*);
        INSERT INTO audit.logged_actions 
        (schema_name, table_name, record_id, user_name, action, original_data, new_data, query)
        VALUES 
        (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, NEW.id, session_user::TEXT, substring(TG_OP,1,1), v_old_data, v_new_data, current_query());
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        v_old_data := ROW(OLD.*);
        INSERT INTO audit.logged_actions 
        (schema_name, table_name, record_id, user_name, action, original_data, query)
        VALUES 
        (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, OLD.id, session_user::TEXT, substring(TG_OP,1,1), v_old_data, current_query());
        RETURN OLD;
    ELSIF (TG_OP = 'INSERT') THEN
        v_new_data := ROW(NEW.*);
        INSERT INTO audit.logged_actions 
        (schema_name, table_name, record_id, user_name, action, new_data, query)
        VALUES 
        (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, NEW.id, session_user::TEXT, substring(TG_OP,1,1), v_new_data, current_query());
        RETURN NEW;
    ELSE
        RAISE WARNING '[AUDIT.LOG_CURRENT_ACTION] - Other action occurred: %, at %', TG_OP, now();
        RETURN NULL;
    END IF;
EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[AUDIT.LOG_CURRENT_ACTION] - Data Exception';
        RETURN NULL;
    WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.LOG_CURRENT_ACTION] - Unique Violation';
        RETURN NULL;
    WHEN others THEN
        RAISE WARNING '[AUDIT.LOG_CURRENT_ACTION] - Other Exception';
        RETURN NULL;
END;
$body$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, audit;



CREATE OR REPLACE FUNCTION audit.log_current_action() RETURNS trigger AS $$
DECLARE
    user_name TEXT;
    v_old_data TEXT;
    v_new_data TEXT;
BEGIN
    user_name := current_setting('app.current_user_id', false);

    IF (TG_OP = 'UPDATE') THEN
        v_old_data := ROW(OLD.*);
        v_new_data := ROW(NEW.*);
        INSERT INTO audit.logged_actions (
            schema_name, table_name, record_id, user_name, action, original_data, new_data, query
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, NEW.id, user_name, 'U', v_old_data, v_new_data, current_query()
        );
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        v_old_data := ROW(OLD.*);
        INSERT INTO audit.logged_actions (
            schema_name, table_name, record_id, user_name, action, original_data, query
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, OLD.id, user_name, 'D', v_old_data, current_query()
        );
        RETURN OLD;
    ELSIF (TG_OP = 'INSERT') THEN
        v_new_data := ROW(NEW.*);
        INSERT INTO audit.logged_actions (
            schema_name, table_name, record_id, user_name, action, new_data, query
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, NEW.id, user_name, 'I', v_new_data, current_query()
        );
        RETURN NEW;
    ELSE
        RAISE WARNING 'Unknown operation: %', TG_OP;
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE TRIGGER tablename_audit
AFTER INSERT OR UPDATE OR DELETE ON tablename
FOR EACH ROW EXECUTE FUNCTION audit.log_current_action();
