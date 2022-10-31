import pandas as pd
import sys

csv_file = sys.argv[1]
xlsx_file_name = sys.argv[2]
data = pd.read_csv(csv_file)
data.to_excel(xlsx_file_name+"_opools_order.xlsx", index=None, header=True)
