INSERT INTO badges (id, name, description, icon_url, category, xp_required)
VALUES
    (gen_random_uuid(), 'Welcome',      'Joined the Pitaya community',            '/images/badges/welcome.svg',      'MILESTONE', 0),
    (gen_random_uuid(), 'First Post',   'Published your first post',              '/images/badges/first-post.svg',    'MILESTONE', 10),
    (gen_random_uuid(), 'Commenter',    'Left your first comment',                '/images/badges/commenter.svg',     'MILESTONE', 5),
    (gen_random_uuid(), 'Popular',      'Received 100 likes on your posts',       '/images/badges/popular.svg',       'ACHIEVEMENT', 200),
    (gen_random_uuid(), 'Social Butterfly', 'Received 1000 likes on your posts',  '/images/badges/social-butterfly.svg', 'ACHIEVEMENT', 2000),
    (gen_random_uuid(), 'Mentor',       'Scheduled your first mentorship session','/images/badges/mentor.svg',        'MILESTONE', 25),
    (gen_random_uuid(), 'Scholar',      'Reached level 10',                       '/images/badges/scholar.svg',       'ACHIEVEMENT', 0),
    (gen_random_uuid(), 'Contributor',  'Reached level 25',                       '/images/badges/contributor.svg',   'ACHIEVEMENT', 0);
