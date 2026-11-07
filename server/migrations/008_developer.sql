-- Role 'developer' (Разработчик / тест-режим): full access across all actions on the project.

ALTER TABLE project_members
  DROP CONSTRAINT project_members_role_check;

ALTER TABLE project_members
  ADD CONSTRAINT project_members_role_check
  CHECK (role IN ('director', 'contractor', 'tech', 'observer', 'developer'));
