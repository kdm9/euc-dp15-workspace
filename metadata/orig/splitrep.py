import csv
import re

records = csv.reader(open("Collection_Eucs_2015_kdm_edited.csv"))
header = next(records)
outf = open("../samples.csv", "w")
out = csv.writer(outf)
out.writerow(header)
for rec in records:
    print(rec)
    subs = rec[1].split("-")
    if len(subs) == 1:
        out.writerow(rec)
    else:
        for alpha in range(ord(subs[0]), ord(subs[1])):
            rec[1] = chr(alpha).lower()
            out.writerow(rec)
