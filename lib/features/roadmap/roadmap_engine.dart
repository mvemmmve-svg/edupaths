// lib/features/roadmap/roadmap_engine.dart
//
// ROADMAP ENGINE — builds a personalised learning journey for any career.
//
// Inputs:  career name + category, the user's current school year, and
//          their preferred pathway (University / Apprenticeship / Both).
// Output:  a CareerRoadmap — staged milestones (Year 10 → Year 11 →
//          Sixth Form/College), an Age-18 route branch (Option A/B/C),
//          and an early-career stage. Stages before the user's current
//          year are marked done; their current stage is highlighted.
//
// Content is data, not code: each career keyword maps to a profile of
// milestones, so a Software Engineer's roadmap is genuinely different
// from a Nurse's or a Mechanical Engineer's — different subjects,
// different actions, different routes, different colours.

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ── Public models ──────────────────────────────────────────────

class RoadmapStage {
  final String title;          // e.g. 'Year 10'
  final String timeLabel;      // e.g. 'NOW' or '2027'
  final String emoji;
  final List<String> milestones;
  final bool done;
  final bool current;
  const RoadmapStage({required this.title, required this.timeLabel,
    required this.emoji, required this.milestones,
    this.done = false, this.current = false});
}

class RouteOption {
  final String emoji, title, duration, detail;
  final Color color;
  final String kind;           // 'uni' | 'app' | 'alt'
  final bool preferred;
  const RouteOption({required this.emoji, required this.title,
    required this.duration, required this.detail, required this.color,
    required this.kind, this.preferred = false});
  RouteOption withPreferred(bool v) => RouteOption(emoji: emoji,
    title: title, duration: duration, detail: detail, color: color,
    kind: kind, preferred: v);
}

class CareerRoadmap {
  final Color color;           // career theme colour (drives the timeline)
  final String emoji;          // career theme emoji
  final List<RoadmapStage> stages;   // study stages, up to the 18+ branch
  final int branchYear;        // calendar year of the Age-18 decision
  final List<RouteOption> routes;    // Option A / B / C at 18
  final RoadmapStage finalStage;     // early career
  const CareerRoadmap({required this.color, required this.emoji,
    required this.stages, required this.branchYear,
    required this.routes, required this.finalStage});
}

// ── Theme per career field (visual differentiation) ────────────

(Color, String) roadmapThemeFor(String? category, String careerName) {
  final c = (category ?? '').toLowerCase();
  final n = careerName.toLowerCase();
  if (c.contains('tech') || n.contains('software') || n.contains('cyber') ||
      n.contains('data') || n.contains('developer')) {
    return (const Color(0xFF5B4FE9), '💻');
  }
  if (c.contains('health') || c.contains('medicine') || n.contains('nurs') ||
      n.contains('doctor') || n.contains('paramedic')) {
    return (const Color(0xFF0E9B76), '🩺');
  }
  if (c.contains('engineer') || n.contains('engineer') ||
      n.contains('electrician') || n.contains('construction')) {
    return (const Color(0xFFFF8C42), '⚙️');
  }
  if (c.contains('creative') || c.contains('media') || n.contains('design') ||
      n.contains('artist') || n.contains('film')) {
    return (const Color(0xFFEC4899), '🎨');
  }
  if (c.contains('business') || c.contains('finance') ||
      n.contains('account') || n.contains('market')) {
    return (const Color(0xFFD97706), '📈');
  }
  if (c.contains('law') || c.contains('social') || n.contains('solicitor') ||
      n.contains('police')) {
    return (const Color(0xFF7C3AED), '⚖️');
  }
  if (c.contains('education') || c.contains('people') || n.contains('teach')) {
    return (const Color(0xFF2456E6), '📚');
  }
  if (c.contains('science') || n.contains('scientist')) {
    return (const Color(0xFF0891B2), '🔬');
  }
  return (AppColors.primary, '💼');
}

// ── Route option helpers ───────────────────────────────────────

RouteOption _uni(String title, String duration, String detail) =>
    RouteOption(emoji: '🎓', title: title, duration: duration,
      detail: detail, color: AppColors.uniRoute, kind: 'uni');

RouteOption _app(String title, String duration, String detail) =>
    RouteOption(emoji: '🔨', title: title, duration: duration,
      detail: detail, color: AppColors.appRoute, kind: 'app');

RouteOption _alt(String emoji, String title, String duration, String detail) =>
    RouteOption(emoji: emoji, title: title, duration: duration,
      detail: detail, color: AppColors.accentOrange, kind: 'alt');

// ── Career profile (the per-career content) ────────────────────

class _P {
  final String gcseFocus;          // shown in the KS3 stage for Y7–9 users
  final List<String> y10, y11, post16, early;
  final List<RouteOption> routes;
  const _P({required this.gcseFocus, required this.y10, required this.y11,
    required this.post16, required this.routes, required this.early});
}

_P _profileFor(String careerName, String? category) {
  final n = careerName.toLowerCase();
  bool has(List<String> keys) => keys.any(n.contains);

  // ── Tech: software / web / apps / games ──
  if (has(['software', 'developer', 'programmer', 'web dev', 'app dev',
      'game', 'devops', 'cloud', 'it support', 'network'])) {
    return _P(
      gcseFocus: 'Maths & Computer Science',
      y10: ['Focus on Maths & Computer Science GCSEs',
        'Learn Python basics — free with CS50 or BBC Bitesize',
        'Build something small: a game, a bot or a website'],
      y11: ['Revise hard — target Grade 6+ in Maths & Computer Science',
        'Put 2–3 finished projects on a GitHub portfolio',
        'Join a coding club or enter a hackathon'],
      post16: ['A-level Maths (essential) + Computer Science',
        'Keep shipping projects — your GitHub is your CV',
        'Apply early: degree apprenticeships open each autumn'],
      routes: [
        _uni('BSc Computer Science', '3 yrs',
          'The classic route. Pick a course with a placement year — it massively boosts job offers.'),
        _app('Software Degree Apprenticeship', '4 yrs',
          'Earn £18–25k while getting a free degree at firms like IBM, BT and PwC. Very competitive — apply to lots.'),
        _alt('⚡', 'T-Level + Bootcamp', '1–2 yrs',
          'Digital T-Level, then an intensive coding bootcamp straight into a junior dev role.'),
      ],
      early: ['Junior Developer → Software Engineer → Senior / Lead',
        'Typical UK graduate salary: £28–45k, rising fast with experience'],
    );
  }

  // ── Tech: cyber security ──
  if (has(['cyber', 'security analyst', 'penetration', 'ethical hack'])) {
    return _P(
      gcseFocus: 'Maths & Computer Science',
      y10: ['Focus on Maths & Computer Science GCSEs',
        'Try free challenges on TryHackMe and CyberFirst (NCSC)',
        'Learn how networks work — build a home lab if you can'],
      y11: ['Target Grade 6+ in Maths & Computer Science',
        'Enter the CyberFirst Girls / CyberCenturion competitions',
        'Document your learning — a blog counts as a portfolio'],
      post16: ['A-level Maths + Computer Science',
        'Apply for a CyberFirst bursary — £4k/yr plus paid summer work',
        'Get certificates: CompTIA Security+ is respected early on'],
      routes: [
        _uni('BSc Cyber Security', '3 yrs',
          'NCSC-certified degrees (check the list) carry real weight with employers.'),
        _app('Cyber Degree Apprenticeship', '4 yrs',
          'Earn while training at GCHQ, BT, banks and defence firms.'),
        _alt('🛡️', 'Certifications route', '1–2 yrs',
          'Stack industry certs (Security+, CEH) + a junior SOC analyst job.'),
      ],
      early: ['SOC Analyst → Security Engineer → Penetration Tester',
        'Cyber salaries climb quickly — £50k+ is common within 5 years'],
    );
  }

  // ── Tech: data / AI ──
  if (has(['data', 'machine learning', 'artificial intelligence', 'ai engineer',
      'analyst', 'statistician'])) {
    return _P(
      gcseFocus: 'Maths (and Computer Science if offered)',
      y10: ['Make Maths your strongest subject — target Grade 7+',
        'Learn Python + pandas basics (free on Kaggle Learn)',
        'Analyse something you care about: FIFA stats, Spotify data'],
      y11: ['GCSE revision — Grade 7+ in Maths opens every door here',
        'Complete a Kaggle beginner competition',
        'Start a mini portfolio of data projects'],
      post16: ['A-level Maths + Further Maths (huge advantage)',
        'Add Computer Science or a science A-level',
        'Enter maths challenges (UKMT) — unis love them'],
      routes: [
        _uni('BSc Data Science / Maths / CS', '3 yrs',
          'A strong maths degree keeps AI, finance and research all open.'),
        _app('Data Degree Apprenticeship', '3–4 yrs',
          'Banks, retailers and the Civil Service all run earn-while-you-learn data schemes.'),
        _alt('🤖', 'MSc conversion later', '+1 yr',
          'Any numerate degree, then a 1-year AI/Data Science masters.'),
      ],
      early: ['Data Analyst → Data Scientist → ML Engineer',
        'AI skills currently command some of the highest grad salaries in the UK'],
    );
  }

  // ── Health: nursing / midwifery ──
  if (has(['nurse', 'nursing', 'midwif'])) {
    return _P(
      gcseFocus: 'Biology, Maths & English',
      y10: ['Focus on Biology, Maths & English GCSEs',
        'Start volunteering — care homes, St John Ambulance, charity shops',
        'Talk to a real nurse about a typical shift'],
      y11: ['Target Grade 5+ in English, Maths & Science (entry requirement)',
        'Log your volunteering hours — unis and trusts ask for evidence',
        'Look up NHS cadet schemes near you'],
      post16: ['A-level Biology, or BTEC/T-Level Health & Social Care',
        'Keep the care experience going — it decides interviews',
        'Attend an NHS careers event or virtual work experience'],
      routes: [
        _uni('BSc Nursing', '3 yrs',
          'Includes NHS placements from year one, plus a £5,000/yr training grant you never pay back.'),
        _app('Nursing Degree Apprenticeship', '4 yrs',
          'Employed by an NHS trust from day one — earn a salary while you qualify.'),
        _alt('🏥', 'Nursing Associate first', '2 yrs',
          'Foundation-degree role, then top up to Registered Nurse while working.'),
      ],
      early: ['Band 5 Registered Nurse (~£29k) → Band 6 specialist',
        'Specialise later: A&E, mental health, midwifery, research'],
    );
  }

  // ── Health: paramedic ──
  if (has(['paramedic', 'ambulance'])) {
    return _P(
      gcseFocus: 'Biology, Maths & English',
      y10: ['Focus on Biology, Maths & English GCSEs',
        'Join St John Ambulance — first aid experience is gold here',
        'Get comfortable under pressure: sport, cadets, DofE'],
      y11: ['Target Grade 5+ in English, Maths & Science',
        'Keep a log of first-aid and volunteering experience',
        'You\'ll need a driving licence eventually — plan for it at 17'],
      post16: ['A-level Biology + one more science, or Health T-Level',
        'Volunteer with an ambulance service if your area offers it',
        'Fitness matters — keep active'],
      routes: [
        _uni('BSc Paramedic Science', '3 yrs',
          'Blue-light placements throughout. Includes the £5,000/yr NHS grant.'),
        _app('Paramedic Degree Apprenticeship', '3–4 yrs',
          'Some ambulance trusts train you on the job — check your local trust.'),
        _alt('🚑', 'Emergency Care Assistant first', '1–2 yrs',
          'Start as an ECA, then progress internally to paramedic training.'),
      ],
      early: ['Newly Qualified Paramedic (~£29k) → Specialist / Advanced Paramedic'],
    );
  }

  // ── Health: doctor / dentist / vet ──
  if (has(['doctor', 'medicine', 'surgeon', 'gp', 'dentist', 'veterinar'])) {
    final isVet = n.contains('vet');
    final isDentist = n.contains('dent');
    return _P(
      gcseFocus: 'Biology, Chemistry & Maths — aim top grades',
      y10: ['Push Biology, Chemistry & Maths — Grade 7+ is the target',
        'Start volunteering now (care settings${isVet ? ', farms, kennels' : ''}) — you need a long record',
        'Read around the subject; keep a reflection diary'],
      y11: ['GCSEs really count here — most offers want 7s and 8s',
        'Arrange work experience: ${isVet ? 'vet practices and farms' : isDentist ? 'a dental surgery' : 'hospitals, GP surgeries, care homes'}',
        'Research the UCAT admissions test — it\'s sat in Year 12/13'],
      post16: ['A-level Chemistry + Biology, aiming A/A*',
        'Sit the UCAT in the summer of Year 12',
        'Draft your personal statement early — reflection beats lists'],
      routes: [
        _uni(isVet ? 'Veterinary Medicine' : isDentist ? 'BDS Dentistry' : 'Medicine (MBBS)',
          '5–6 yrs',
          'The main route. Apply to 4 courses via UCAS by the mid-October deadline.'),
        _app(isDentist || isVet ? 'Gateway / foundation year' : 'Medical Doctor Degree Apprenticeship',
          '5–6 yrs',
          isDentist || isVet
            ? 'Gateway years exist for students from under-represented backgrounds — lower entry grades.'
            : 'Brand-new NHS route with a salary — tiny numbers so far, treat it as a bonus application.'),
        _alt('🔬', 'Graduate entry', '4 yrs (after a degree)',
          'Do Biomedical Science first, then a shortened graduate-entry course.'),
      ],
      early: [isVet ? 'Newly qualified vet → specialist certificates'
        : 'Foundation doctor (FY1/FY2) → specialty training',
        'A long road — but one of the most secure careers in the UK'],
    );
  }

  // ── Health: allied (physio, radiography, OT, pharmacy…) ──
  if (has(['physio', 'occupational therap', 'radiograph', 'speech',
      'pharmac', 'optometr', 'dietit', 'podiatr', 'therapist'])) {
    return _P(
      gcseFocus: 'Biology, Maths & English',
      y10: ['Focus on Biology, Maths & English GCSEs',
        'Volunteer in a health or care setting',
        'Shadow the role if you can — even one day helps'],
      y11: ['Target Grade 5+ in English, Maths & Science',
        'Keep evidence of your people skills — coaching, mentoring, clubs',
        'Research which unis offer your exact course (numbers are small)'],
      post16: ['A-level Biology + one more science or PE',
        'Most allied health degrees carry the £5,000/yr NHS grant',
        'Book an open day — placements differ a lot between unis'],
      routes: [
        _uni('BSc in your specialism', '3–4 yrs',
          'Placement-heavy degrees with strong NHS employment rates.'),
        _app('Degree Apprenticeship', '3–4 yrs',
          'Growing fast in physiotherapy, radiography and podiatry — employed by a trust while you train.'),
        _alt('🏥', 'Support worker first', '1–2 yrs',
          'Start as a therapy/healthcare assistant, then train up internally.'),
      ],
      early: ['Band 5 NHS start (~£29k) → Band 6/7 specialist'],
    );
  }

  // ── Engineering (mechanical, civil, electrical, aero, chemical…) ──
  if (has(['engineer', 'engineering']) && !has(['software', 'sound'])) {
    return _P(
      gcseFocus: 'Maths, Physics & Design Technology',
      y10: ['Push Maths & Physics — Grade 7 is the goal',
        'Build and fix things: Greenpower, robotics club, model kits',
        'Take Design & Technology seriously — it\'s applied engineering'],
      y11: ['Apply for an Arkwright Engineering Scholarship (apply in Year 11!)',
        'GCSE revision — Maths & Physics carry everything here',
        'Visit an engineering employer open day (Rolls-Royce, JLR, BAE run them)'],
      post16: ['A-level Maths + Physics (Further Maths is a big advantage)',
        'Do a Headstart residential taster course in Year 12',
        'Apply BOTH routes: UCAS and degree apprenticeships'],
      routes: [
        _uni('MEng Engineering', '4 yrs',
          'Integrated masters is the fast track to Chartered Engineer status.'),
        _app('Engineering Degree Apprenticeship', '4–6 yrs',
          'Rolls-Royce, BAE, JLR, Network Rail — earn £18–25k with a free degree.'),
        _alt('🔩', 'HNC/HND via college', '2 yrs',
          'Hands-on higher qualification, top up to a degree later if you want.'),
      ],
      early: ['Graduate Engineer → Chartered Engineer (CEng)',
        'Chartership typically adds £10k+ to your salary'],
    );
  }

  // ── Skilled trades ──
  if (has(['electrician', 'plumb', 'carpent', 'construction', 'builder',
      'bricklay', 'mechanic', 'welder', 'joiner'])) {
    return _P(
      gcseFocus: 'Maths, English & Design Technology',
      y10: ['Keep Maths & English solid — apprenticeships require passes',
        'Take DT/Engineering GCSE if your school offers it',
        'Do hands-on projects at home — evidence you love the work'],
      y11: ['Pass Maths & English (Grade 4+) — the key that unlocks apprenticeships',
        'Research local training providers and employers NOW',
        'Apprenticeship applications open in spring — don\'t wait for results day'],
      post16: ['Start a Level 2/3 apprenticeship, or a college diploma first',
        'Get your CSCS card sorted for site access',
        'Every project you help with builds your reputation'],
      routes: [
        _app('Level 3 Apprenticeship', '3–4 yrs',
          'THE main route — earn from day one and qualify on the job. Qualified trades regularly out-earn graduates.'),
        _alt('🏗️', 'College diploma first', '1–2 yrs',
          'Full-time training, then jump into an apprenticeship or job with a head start.'),
        _uni('HNC / management later', 'optional',
          'Once qualified, top up towards site management or running your own firm.'),
      ],
      early: ['Qualified trade (~£32–45k) → self-employed or site supervisor',
        'Experienced electricians and plumbers can clear £50k+'],
    );
  }

  // ── Law ──
  if (has(['law', 'solicitor', 'barrister', 'paralegal', 'legal'])) {
    return _P(
      gcseFocus: 'English — plus consistently strong grades overall',
      y10: ['Make English your strongest subject',
        'Join (or start) a debate club — advocacy is a muscle',
        'Follow one big court case in the news and form your own view'],
      y11: ['Target Grade 6+ in English; law firms check GCSEs later',
        'Apply for free programmes: Sutton Trust Pathways to Law',
        'Do a mock trial — many schools and courts run them'],
      post16: ['Any 3 strong A-levels — essay subjects (English, History) respected',
        'Attend law firm insight days (they run schemes for Year 12s)',
        'Decide: LLB at uni vs solicitor apprenticeship'],
      routes: [
        _uni('LLB Law → SQE', '3 yrs + training',
          'Law degree, then the Solicitors Qualifying Exam and qualifying work experience.'),
        _app('Solicitor Apprenticeship', '6 yrs',
          'Straight from school at big firms — earn a salary, qualify with zero uni debt.'),
        _alt('📜', 'Any degree + conversion', '3 yrs + 1',
          'Study anything you love, then a law conversion course (PGDL).'),
      ],
      early: ['Trainee/apprentice → Newly Qualified solicitor',
        'NQ salaries: £30k regional firms up to £100k+ in London City firms'],
    );
  }

  // ── Police / justice ──
  if (has(['police', 'probation', 'criminolog', 'detective', 'prison'])) {
    return _P(
      gcseFocus: 'English & Maths, plus fitness',
      y10: ['Keep English & Maths strong',
        'Join Police Cadets — direct insight and great on applications',
        'Stay fit — there\'s a physical entrance test'],
      y11: ['Pass English & Maths (Grade 4+)',
        'Volunteer in your community — evidence of judgement and service',
        'A clean record matters: think about your digital footprint too'],
      post16: ['Any A-levels/T-Level — Criminology, Law, Sociology all fit',
        'Continue cadets or volunteering',
        'Research your local force\'s entry routes — they differ'],
      routes: [
        _app('Police Constable Entry Programme', '2–3 yrs',
          'Join at 18, earn a full salary while training on the job.'),
        _uni('Degree first, then join', '3 yrs',
          'Criminology or any degree, then the graduate entry programme (faster to detective).'),
        _alt('🕵️', 'Detective Entry route', '2 yrs',
          'Some forces let you train directly as a detective constable.'),
      ],
      early: ['PC (~£29k) → Sergeant → Inspector, or specialist units'],
    );
  }

  // ── Teaching ──
  if (has(['teacher', 'teaching', 'lecturer', 'tutor'])) {
    return _P(
      gcseFocus: 'English & Maths (both required for teacher training)',
      y10: ['Grade 5+ in English & Maths is legally required later — bank them now',
        'Help younger students: peer mentoring, sports coaching, clubs',
        'Notice which subject you\'d love to teach'],
      y11: ['Secure those English & Maths grades',
        'Ask to help at a primary school event or open evening',
        'Keep your specialist subject grade high (6+ ideally)'],
      post16: ['A-levels including your teaching subject',
        'Get classroom experience — schools welcome sixth-form helpers',
        'Look up teacher training bursaries: shortage subjects pay up to £28k tax-free'],
      routes: [
        _uni('Degree + PGCE', '3 yrs + 1',
          'Subject degree first, then a one-year teacher training course with school placements.'),
        _app('Teacher Degree Apprenticeship', '4 yrs',
          'New route from 2025 — earn while you train, no tuition fees.'),
        _alt('🍎', 'BEd (primary)', '3 yrs',
          'Education degree with Qualified Teacher Status built in.'),
      ],
      early: ['ECT (~£31k+ outside London, more inside) → Head of Department'],
    );
  }

  // ── Psychology / social work ──
  if (has(['psycholog', 'counsell', 'social work', 'youth work', 'therapy'])) {
    return _P(
      gcseFocus: 'English, Maths & Science',
      y10: ['Keep English, Maths & Science solid',
        'Volunteer with people: youth clubs, helplines, mentoring',
        'Read one accessible psychology book — see if it grips you'],
      y11: ['Target Grade 5+ in English, Maths & Science',
        'Build a record of listening/helping roles',
        'Look into peer-support training at school'],
      post16: ['A-level Psychology + Biology or Sociology',
        'Keep volunteering — clinical routes are experience-hungry',
        'Understand the long game: clinical psychology needs a doctorate'],
      routes: [
        _uni('BSc Psychology (BPS-accredited)', '3 yrs',
          'Accreditation matters — it\'s the gateway to every psychology career.'),
        _app('Social Worker Degree Apprenticeship', '3 yrs',
          'Employed by a council while you qualify — strong job security.'),
        _alt('💬', 'PWP / support roles first', '1–2 yrs',
          'Work as a Psychological Wellbeing Practitioner in the NHS, then specialise.'),
      ],
      early: ['Assistant Psychologist / support roles → specialist training',
        'Patience pays: qualified clinical psychologists reach £50k+ in the NHS'],
    );
  }

  // ── Finance / accounting ──
  if (has(['account', 'financ', 'bank', 'actuar', 'econom', 'invest',
      'audit', 'tax'])) {
    return _P(
      gcseFocus: 'Maths — make it your headline grade',
      y10: ['Push Maths hard — Grade 7+ target',
        'Learn the basics: what are shares, interest, budgets?',
        'Run a mini venture — even reselling teaches you margins'],
      y11: ['GCSE Maths grade is checked by employers years later',
        'Enter a student investor or fintech challenge',
        'Research school-leaver programmes at the Big 4 (they\'re real jobs)'],
      post16: ['A-level Maths + Economics or Business',
        'Apply for spring/insight weeks at banks and accounting firms in Year 12',
        'Decide: uni + grad scheme vs school-leaver apprenticeship'],
      routes: [
        _uni('BSc Economics / Accounting & Finance', '3 yrs',
          'Then a graduate scheme with ACA/CFA training on top.'),
        _app('Accountancy Apprenticeship (AAT → ACA)', '5 yrs',
          'PwC, KPMG, Deloitte and EY hire straight from school — salary + fully-funded chartered qualification.'),
        _alt('📊', 'Actuarial / banking school-leaver schemes', '3–5 yrs',
          'Insurers and banks run structured earn-and-qualify programmes.'),
      ],
      early: ['Trainee → Chartered Accountant / Analyst',
        'Newly chartered accountants typically earn £45–60k'],
    );
  }

  // ── Business / marketing / entrepreneurship ──
  if (has(['business', 'market', 'entrepreneur', 'manager', 'hr ',
      'human resources', 'consult', 'sales', 'event', 'product'])) {
    return _P(
      gcseFocus: 'English & Maths, plus Business if offered',
      y10: ['Keep English & Maths strong',
        'Start something tiny: a social account, a stall, a service',
        'Study brands you love — WHY do they work on you?'],
      y11: ['GCSE revision — then analyse your own revision like a project',
        'Enter Young Enterprise or a school business competition',
        'Build a LinkedIn-ready story: what have you actually done?'],
      post16: ['A-level Business/Economics + anything you\'re great at',
        'Run or grow a real micro-project — evidence beats theory',
        'Chase insight days: marketing agencies and consultancies run them'],
      routes: [
        _uni('BSc Business / Marketing', '3 yrs',
          'Choose one with a placement year — experience is the differentiator.'),
        _app('Business / Marketing Degree Apprenticeship', '3–4 yrs',
          'Unilever, Google, M&S and co. — degree + salary + real campaigns.'),
        _alt('🚀', 'Start something + learn on the job', 'ongoing',
          'Junior roles or your own venture; the CIM offers marketing quals part-time.'),
      ],
      early: ['Exec/coordinator → Manager → Head of…',
        'Marketing and ops managers commonly reach £40–60k'],
    );
  }

  // ── Design / architecture / visual creative ──
  if (has(['design', 'architect', 'illustrat', 'animat', 'fashion',
      'interior', 'graphic', 'artist', 'photograph', 'ux', 'product design'])) {
    return _P(
      gcseFocus: 'Art & Design (+ Maths for architecture)',
      y10: ['Take Art/Design GCSE seriously — start a sketchbook habit',
        'Learn one tool properly: Procreate, Figma, Blender (free!)',
        'Post your work somewhere — feedback accelerates you'],
      y11: ['Your PORTFOLIO matters more than any grade — build it all year',
        'Enter a young designer/artist competition',
        'Visit a degree show — see the standard you\'re aiming at'],
      post16: ['A-level Art/Design/Graphics (+ Maths & Physics for architecture)',
        'Portfolio, portfolio, portfolio — 10 strong pieces beat 50 okay ones',
        'Consider an Art Foundation year — the classic springboard'],
      routes: [
        _uni('BA Design / BArch Architecture', '3–7 yrs',
          'Architecture is a 7-year path (BArch + MArch + practice) — worth knowing early.'),
        _app('Design / Architecture Apprenticeship', '4–6 yrs',
          'Architectural apprenticeships now go all the way to qualification, salary included.'),
        _alt('🎨', 'Foundation year + freelance', '1 yr +',
          'Art Foundation, then build a client base while studying part-time.'),
      ],
      early: ['Junior Designer → Midweight → Senior / Art Director',
        'Your portfolio, not your CV, wins every creative job'],
    );
  }

  // ── Media / journalism / film / music / performance ──
  if (has(['journalis', 'media', 'film', 'writer', 'music', 'actor',
      'content', 'editor', 'radio', 'presenter', 'sound'])) {
    return _P(
      gcseFocus: 'English (+ Media/Music/Drama if offered)',
      y10: ['Make things NOW: videos, articles, tracks, performances',
        'Keep English strong — every media career needs it',
        'Consume like a critic: why does that video/song/article work?'],
      y11: ['Build a public body of work — a channel, blog or portfolio',
        'Join school productions, the newspaper, or start the thing yourself',
        'GCSE revision — but keep one creative project alive'],
      post16: ['A-level English/Media + your craft subject',
        'Apply for BBC Young Reporter, film festivals, open mics',
        'Get real credits: local papers, hospital radio, student films'],
      routes: [
        _uni('BA Journalism / Film / Music', '3 yrs',
          'Pick courses with industry links and kit — the showreel you leave with matters most.'),
        _app('Broadcast / Content Apprenticeships', '1–2 yrs',
          'The BBC, ITV, Sky and Channel 4 all run paid apprenticeships.'),
        _alt('🎬', 'Portfolio + runner route', 'ongoing',
          'Start as a runner/assistant, out-hustle everyone, build credits.'),
      ],
      early: ['Assistant/junior → credited roles → your own projects',
        'Media pay starts modest — momentum and contacts compound fast'],
    );
  }

  // ── Science ──
  if (has(['scientist', 'biolog', 'chemis', 'physic', 'environment',
      'lab', 'forensic', 'marine', 'geolog', 'astro'])) {
    return _P(
      gcseFocus: 'Triple Science & Maths',
      y10: ['Take Triple Science if offered; push Maths too',
        'Do a real experiment beyond class — CREST Awards are free',
        'Follow actual research news, not just textbooks'],
      y11: ['Target Grade 6–7+ in Sciences & Maths',
        'Apply for a Nuffield Research Placement (Year 12 summer — plan now)',
        'Visit a university science open day'],
      post16: ['A-level in your science + Maths',
        'Do that Nuffield placement — real research on your UCAS form',
        'Enter Olympiads in your subject'],
      routes: [
        _uni('BSc / MSci in your science', '3–4 yrs',
          'The main route; integrated masters (MSci) helps for research careers.'),
        _app('Laboratory Scientist Apprenticeship', '3–5 yrs',
          'Pharma and materials firms (GSK, AstraZeneca) train degree apprentices in real labs.'),
        _alt('🔭', 'Technician route', '2 yrs',
          'Level 3 lab technician apprenticeship, then climb or top up.'),
      ],
      early: ['Research assistant / lab scientist → specialist or PhD',
        'Industry science pays better than academia early on'],
    );
  }

  // ── Sport & fitness ──
  if (has(['sport', 'coach', 'personal trainer', 'fitness', 'athlete',
      'physio']) ) {
    return _P(
      gcseFocus: 'PE, Biology & English',
      y10: ['Take GCSE PE; keep Biology strong',
        'Coach younger kids — clubs always need helpers',
        'Get a first-aid certificate'],
      y11: ['Start a Level 1 coaching award in your sport',
        'Keep competing — but build the coaching CV alongside',
        'GCSE revision: sport science needs Biology'],
      post16: ['A-level PE + Biology, or Sport BTEC/T-Level',
        'Stack coaching badges and hours',
        'Shadow a PT, physio or performance analyst'],
      routes: [
        _uni('BSc Sport Science', '3 yrs',
          'Opens coaching, performance analysis, S&C and teaching routes.'),
        _app('Sporting Excellence / Coaching Apprenticeship', '1–3 yrs',
          'Clubs and gym chains train coaches and PTs on the job.'),
        _alt('🏋️', 'PT qualification direct', '3–6 months',
          'Level 3 Personal Trainer diploma — earning quickly, build your client base.'),
      ],
      early: ['Coach/PT → specialist (S&C, analysis) or own business'],
    );
  }

  // ── Category fallbacks ──
  final c = (category ?? '').toLowerCase();
  if (c.contains('health')) {
    return _profileFor('nurse', category);
  }
  if (c.contains('tech')) {
    return _profileFor('software developer', category);
  }
  if (c.contains('engineer')) {
    return _profileFor('engineer', category);
  }
  if (c.contains('creative') || c.contains('media')) {
    return _profileFor('designer', category);
  }
  if (c.contains('business') || c.contains('finance')) {
    return _profileFor('business', category);
  }
  if (c.contains('law') || c.contains('social')) {
    return _profileFor('law', category);
  }
  if (c.contains('education') || c.contains('people')) {
    return _profileFor('teacher', category);
  }

  // ── Generic fallback ──
  return _P(
    gcseFocus: 'Maths, English + subjects closest to this field',
    y10: ['Keep Maths & English strong — they underpin every route',
      'Find one person doing this job and ask them 3 questions',
      'Start a project connected to this career, however small'],
    y11: ['GCSE revision — Grade 5+ in Maths & English keeps doors open',
      'Do work experience or job-shadowing in this field',
      'Research exact entry requirements on the National Careers Service'],
    post16: ['Choose A-levels/T-Levels that match this career\'s entry routes',
      'Build evidence: projects, volunteering, part-time work',
      'Compare university AND apprenticeship routes before Year 13'],
    routes: [
      _uni('Related degree', '3 yrs',
        'Check typical entry requirements for this field on UCAS.'),
      _app('Apprenticeship route', '2–4 yrs',
        'Search gov.uk/apply-apprenticeship for live vacancies in this field.'),
      _alt('🧭', 'College / direct entry', 'varies',
        'Some roles value experience and short courses over degrees.'),
    ],
    early: ['Entry-level role → build experience → specialise'],
  );
}

// ── The builder ────────────────────────────────────────────────

CareerRoadmap buildCareerRoadmap({
  required String careerName,
  String? category,
  required String schoolYear,
  String? preferredPathway, // 'University' | 'Apprenticeship' | 'Both'
}) {
  final p = _profileFor(careerName, category);
  final (color, emoji) = roadmapThemeFor(category, careerName);

  // ── Where is the user right now? ──
  final sy = schoolYear.toLowerCase();
  // 0 = KS3 (Y7–9), 1 = Y10, 2 = Y11, 3 = Sixth Form / College
  int cur;
  if (sy.contains('12') || sy.contains('13') ||
      sy.contains('sixth') || sy.contains('college')) {
    cur = 3;
  } else if (sy.contains('10')) {
    cur = 1;
  } else if (sy.contains('11')) {
    cur = 2;
  } else if (sy.contains('7') || sy.contains('8') || sy.contains('9')) {
    cur = 0;
  } else {
    cur = 2; // sensible default
  }

  // ── Calendar years ──
  final now = DateTime.now().year;
  final gcseYear = switch (cur) {
    0 => now + 3, 1 => now + 2, 2 => now + 1, _ => now - 1,
  };
  final branchYear = gcseYear + 2; // end of sixth form / college

  String label(int stageIdx, String futureLabel) {
    if (stageIdx == cur) return 'NOW';
    if (stageIdx < cur) return 'DONE';
    return futureLabel;
  }

  final stages = <RoadmapStage>[
    if (cur == 0)
      RoadmapStage(
        title: 'Years 7–9', timeLabel: 'NOW', emoji: '🧭',
        current: true,
        milestones: [
          'Try everything — clubs, subjects, projects',
          'Notice which lessons fly by fastest',
          'Pick GCSE options with this career in mind: ${p.gcseFocus}',
        ]),
    RoadmapStage(
      title: 'Year 10', timeLabel: label(1, '${gcseYear - 1}'),
      emoji: '📚', milestones: p.y10,
      done: cur > 1, current: cur == 1),
    RoadmapStage(
      title: 'Year 11', timeLabel: label(2, '$gcseYear'),
      emoji: '✏️', milestones: p.y11,
      done: cur > 2, current: cur == 2),
    RoadmapStage(
      title: 'Sixth Form / College', timeLabel: label(3, '$gcseYear–$branchYear'),
      emoji: '🎒', milestones: p.post16,
      done: false, current: cur == 3),
  ];

  // ── Route options, with the user's preference badged first ──
  final pref = (preferredPathway ?? '').toLowerCase();
  var routes = p.routes.map((r) {
    final preferred = (pref == 'university' && r.kind == 'uni') ||
        (pref == 'apprenticeship' && r.kind == 'app');
    return r.withPreferred(preferred);
  }).toList();
  // Preferred route floats to the top (Option A)
  routes.sort((a, b) => (b.preferred ? 1 : 0) - (a.preferred ? 1 : 0));

  final finalStage = RoadmapStage(
    title: 'Become a $careerName', timeLabel: '${branchYear + 3}+',
    emoji: '💼', milestones: p.early);

  return CareerRoadmap(color: color, emoji: emoji, stages: stages,
    branchYear: branchYear, routes: routes, finalStage: finalStage);
}
