# Wrappers for Great Expectations or simple checks
def not_null(series):
    return series.notna().all()
