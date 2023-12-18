import requests
import psycopg2
import datetime


def get_schedule_name(conn, cur, schedule_id):
    select = """
        SELECT schedule_type_name FROM Support_Schedules WHERE id = %s;
    """
    cur.execute(select, (schedule_id, ))
    return cur.fetchone()


def update_schedule(conn, cur, spec_id, schedule_name):
    update_query = """
        UPDATE Technical_Supports SET support_status = %s 
            WHERE id = %s;
    """

    if schedule_name == 'С перерывами':
        if ((10 <= datetime.datetime.now().hour <= 12)
                or (14 <= datetime.datetime.now().hour <= 16)
                or (18 <= datetime.datetime.now().hour <= 22)):
            cur.execute(update_query, (True, spec_id))
        else:
            cur.execute(update_query, (False, spec_id))
    elif schedule_name == 'Без перерывов':
        if 9 <= datetime.datetime.now().hour <= 17:
            cur.execute(update_query, (True, spec_id))
        else:
            cur.execute(update_query, (False, spec_id))
    conn.commit()


def main():
    conn = psycopg2.connect(
            database="BankingSystem_Coursework",
            user="postgres",
            password="Dovgun2002",
            host="localhost",
            port="5432"
    )
    cur = conn.cursor()

    select_spec = """
        SELECT id, schedule_type_id FROM Technical_Supports;
    """
    cur.execute(select_spec)
    specialists = cur.fetchall()
    for spec in specialists:
        name = get_schedule_name(conn, cur, spec[1])[0]
        update_schedule(conn, cur, spec[0], name)

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
