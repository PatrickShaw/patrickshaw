SELECT DISTINCT City FROM STATION WHERE Lower(substr(city, -1)) in ('a','e','i','o','u') and lower(substr(city, 1,1)) in ('a','e','i','o','u') ORDER BY city ASC;