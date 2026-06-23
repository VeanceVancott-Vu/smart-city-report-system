-- Set default password 'Password123' for the demo citizen user if it has no password hash
UPDATE users
SET password_hash = '$2a$10$FYJ2fxRr7hOo45jyDJTGi.zAO8Lz7JYUAC5vSYK0535aq5spRBvgW'
WHERE email = 'demo.citizen@example.local' AND password_hash IS NULL;
