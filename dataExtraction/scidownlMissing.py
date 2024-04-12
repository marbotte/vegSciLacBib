import pandas as pd
from scidownl import scihub_download
missingPdf =   pd.read_csv("../../vegSciLacBib_export/id_doi_missing.csv")

ptype = "doi"
res = scihub_download(missingPdf.DOI[0], paper_type = ptype, out = "~/tmp/")
https://onlinelibrary.wiley.com/doi/epdf/10.1111/jvs.13200
