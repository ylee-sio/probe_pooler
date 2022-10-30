import pandas as pd
import sys
from contextlib import suppress

with suppress(Exception):

	csv_file = sys.argv[1]
	gene_name = str(sys.argv[2])
	amplifier = str(sys.argv[3])

	data = pd.read_csv(csv_file)
	data.to_excel("lp_"+gene_name+"_"+amplifier+"_opools_order.xlsx", index=None, header=True)
