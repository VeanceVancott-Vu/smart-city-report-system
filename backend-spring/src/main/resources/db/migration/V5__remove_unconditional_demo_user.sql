DELETE FROM users demo_user
WHERE demo_user.id = '00000000-0000-0000-0000-000000000001'
  AND demo_user.email = 'demo.citizen@example.local'
  AND NOT EXISTS (
      SELECT 1
      FROM reports report
      WHERE report.created_by_user_id = demo_user.id
  );
