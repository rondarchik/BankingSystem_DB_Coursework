import requests
import psycopg2
from pycbrf.toolbox import ExchangeRates
import datetime
import itertools


def create_exchanges(conn, cur, from_currency, to_currency):
    insert_query = """
        INSERT INTO Currency_Rates (base_currency_id, target_currency_id, exchange_rate) VALUES (%s, %s, %s);
    """
    cur.execute(insert_query, (from_currency, to_currency, 0))
    conn.commit()


def update_exchange_rate(conn, cur, from_currency, to_currency, rate):
    update_query = """
        UPDATE Currency_Rates SET exchange_rate = %s, last_updated = %s 
            WHERE base_currency_id = %s AND target_currency_id = %s;
    """

    cur.execute(update_query, (rate, datetime.datetime.now(), from_currency, to_currency))
    conn.commit()


def main():
    rates = ExchangeRates(datetime.datetime.now())
    conn = psycopg2.connect(
            database="BankingSystem_Coursework",
            user="postgres",
            password="Dovgun2002",
            host="localhost",
            port="5432"
    )
    cur = conn.cursor()

    select_currencies_query = """
            SELECT id, currency_code FROM Currencies;
        """
    cur.execute(select_currencies_query)
    res = cur.fetchall()

    currencies = {}
    for item in res:
        currencies[item[1]] = item[0]

    currency = [str(res[i][1]) for i in range(len(res))]

    pairs = []
    for pair in list(itertools.product(currency, currency)):
        if pair[0] != pair[1]:
            pairs.append(pair)

    for cur1 in currency:
        for cur2 in currency:
            if cur1 != cur2:
                create_exchanges(conn, cur, currencies[cur1], currencies[cur2])
                rate = rates[f'{cur2}'].rate / rates[f'{cur1}'].rate
                update_exchange_rate(conn, cur, currencies[cur1], currencies[cur2], round(rate, 2))
    #
    # rates_query = """
    #     SELECT * FROM Currency_Rates;
    # """
    # cur.execute(rates_query)
    # res = cur.fetchall()
    # print(res)

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
