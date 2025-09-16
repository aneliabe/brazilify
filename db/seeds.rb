# db/seeds.rb — Brazilify demo seed (global users, workers, chats, reviews)
require "securerandom"
require "digest/md5"

# ---------------- Optional Faker (pt-BR) ----------------
begin
  require "faker"
  Faker::Config.locale = "pt-BR"
rescue LoadError
  puts "⚠️  Gem 'faker' not found. Adicione no Gemfile (grupo :development) para textos melhores."
end

# ---------------- Helpers ----------------
BR_NAMES = %w[
  Ana\ Paula Bruno\ Souza Camila\ Ribeiro Daniel\ Almeida Eduardo\ Nunes
  Fernanda\ Rocha Gabriel\ Martins Helena\ Carvalho Igor\ Pereira
  Juliana\ Ferreira Karina\ Souza Leonardo\ Gomes Mariana\ Silva
  Natália\ Costa Otávio\ Azevedo Patrícia\ Mello Rafael\ Lima
  Sabrina\ Duarte Tiago\ Barros Vanessa\ Moreira Wagner\ Cardoso
  Yasmin\ Araújo Zé\ Roberto Jorge\ Aragão Paula\ Fernandes
  João\ Pedro Felipe\ Ramos Beatriz\ Albuquerque
].freeze

def brazilian_name
  if defined?(Faker) && Faker.const_defined?("Name")
    Faker::Name.name
  else
    BR_NAMES.sample
  end
end

def set_if_has(record, field, value)
  return if value.nil?
  if record.respond_to?(:"#{field}=")
    record.public_send(:"#{field}=", value)
  elsif record.has_attribute?(field)
    record[field] = value
  end
end

def set_brazilian_name!(user, force: false)
  current =
    if user.respond_to?(:full_name) && user.full_name.present?
      user.full_name
    else
      [user.try(:first_name), user.try(:last_name)].compact.join(" ")
    end

  needs = force || current.blank? || current.match?(/\A(Usuário|User)\s+Demo\b/i)
  if needs
    name = brazilian_name
    if user.respond_to?(:full_name=)
      user.full_name = name
    else
      first, last = name.split(" ", 2)
      set_if_has(user, :first_name, first || "Nome")
      set_if_has(user, :last_name,  last  || "Sobrenome")
    end
  end
end

def stable_avatar_for(seed)
  n = (Digest::MD5.hexdigest(seed.to_s).to_i(16) % 70) + 1 # 1..70 (pravatar)
  "https://i.pravatar.cc/150?img=#{n}"
end

def uniq_cpf(n)
  "%011d" % (9_000_000_000 + n)
end

def make_message!(appointment, author, text)
  Message.create!(appointment: appointment, user: author, content: text)
end

def lshort(t)
  I18n.l(t, format: :short) rescue t.strftime("%d/%m %H:%M")
end

# --------- Geo (country, city, time zone) ---------
WORLD_CITIES = [
  ["Brasil",          "São Paulo",        "America/Sao_Paulo"],
  ["Brasil",          "Rio de Janeiro",   "America/Sao_Paulo"],
  ["Portugal",        "Lisboa",           "Europe/Lisbon"],
  ["Estados Unidos",  "New York",         "America/New_York"],
  ["Canadá",          "Toronto",          "America/Toronto"],
  ["Reino Unido",     "London",           "Europe/London"],
  ["Alemanha",        "Berlin",           "Europe/Berlin"],
  ["Espanha",         "Madrid",           "Europe/Madrid"],
  ["Argentina",       "Buenos Aires",     "America/Argentina/Buenos_Aires"],
  ["México",          "Cidade do México", "America/Mexico_City"],
  ["Chile",           "Santiago",         "America/Santiago"],
  ["Japão",           "Tóquio",           "Asia/Tokyo"],
  ["Austrália",       "Sydney",           "Australia/Sydney"],
  ["Índia",           "Mumbai",           "Asia/Kolkata"]
].freeze

def sample_geo
  country, city, tz = WORLD_CITIES.sample
  { country: country, city: city, time_zone: tz }
end

# --------- Catalog (categories & services) ----------
CATEGORIES = [
  "Construção", "Tecnologia", "Beleza / Estética", "Serviços Automotivos",
  "Manutenção Residencial", "Saúde e Bem-estar", "Educação",
  "Transporte e Logística", "Serviços Domésticos", "Eventos",
  "Animais de Estimação", "Administração / Negócios", "Arte e Artesanato"
].freeze

SERVICES_BY_CATEGORY = {
  "Construção" => ["Pedreiro", "Pintura", "Eletricista"],
  "Tecnologia" => ["Suporte de TI", "Criação de Sites", "Designer"],
  "Beleza / Estética" => [
    "Cabeleireiro", "Manicure", "Maquiagem",
    "Corte feminino/masculino/infantil", "Escova/chapinha/babyliss",
    "Coloração e mechas", "Progressiva/alisamento", "Hidratação",
    "Alongamento de unhas", "Nail art", "Limpeza de pele", "Sobrancelhas",
    "Micropigmentação", "Cílios", "Drenagem", "Massagem modeladora",
    "Depilação", "Bronzeamento", "Tratamento celulite/estrias",
    "Massagem relaxante", "Aromaterapia", "Reflexologia", "Spa day"
  ],
  "Serviços Automotivos" => [
    "Troca de óleo", "Revisão", "Mecânica", "Suspensão e freios",
    "Diagnóstico eletrônico", "Bateria e alternador", "Som e acessórios",
    "Funilaria e pintura", "Desamassar", "Polimento técnico",
    "Lavagem completa", "Higienização de estofados",
    "Cristalização/Vitrificação", "Envelopamento",
    "Pneus e balanceamento", "Alinhamento",
    "Lâmpadas e palhetas", "Ar-condicionado automotivo",
    "Blindagem", "Película (insulfilm)", "Reparo de vidros"
  ],
  "Manutenção Residencial" => [
    "Encanador", "Eletricista", "Montagem de Móveis", "Marcenaria",
    "Instalação de Ar-Condicionado", "Drywall/Gesso", "Chaveiro",
    "Dedetização", "Portas e Janelas", "Telhados", "Jardinagem",
    "Paisagismo", "Pintura", "Cortinas e Persianas", "Reforma de Banheiros"
  ],
  "Saúde e Bem-estar" => ["Personal Trainer", "Nutricionista", "Fisioterapeuta", "Massoterapeuta", "Psicólogo"],
  "Educação" => ["Reforço Escolar", "Idiomas", "Música", "Dança", "Concursos"],
  "Transporte e Logística" => ["Motorista Particular", "Motoboy", "Frete/Carretos", "Transporte Escolar", "Entregador"],
  "Serviços Domésticos" => ["Diarista", "Passadeira", "Babá", "Cuidador de Idosos", "Lavanderia"],
  "Eventos" => ["Fotógrafo", "Filmagem", "DJ", "Buffet", "Decorador"],
  "Animais de Estimação" => ["Passeador de Cães", "Adestrador", "Pet Sitter", "Banho e Tosa", "Hospedagem"],
  "Administração / Negócios" => ["Consultoria Financeira", "Contador", "Marketing Digital", "Redes Sociais", "Consultoria Jurídica"],
  "Arte e Artesanato" => ["Costureira", "Bordado", "Artesanato Personalizado", "Restauração de Móveis", "Designer de Joias"]
}.freeze

# ======================================================
# ================ SEED EXECUTION ======================
# ======================================================
ActiveRecord::Base.transaction do
  now = Time.zone.now

  # ---------- Clean (dev): rebuild dynamic data ----------
  if Rails.env.development?
    puts "🧹 Limpando dados de demo (mantendo tabela de usuários e catálogo)…"
    Message.destroy_all        if defined?(Message)
    Review.destroy_all         if defined?(Review)
    Appointment.destroy_all    if defined?(Appointment)
    WorkerService.destroy_all  if defined?(WorkerService)
    WorkerProfile.destroy_all  if defined?(WorkerProfile)
  end

  # ---------- Categories & Services ----------
  puts "📚 Populando catálogo…"
  CATEGORIES.each { |name| Category.find_or_create_by!(name: name) }
  SERVICES_BY_CATEGORY.each do |cat_name, list|
    cat = Category.find_or_create_by!(name: cat_name)
    list.each { |srv| Service.find_or_create_by!(name: srv, category: cat) }
  end
  puts "✅ Catálogo pronto (#{Category.count} categorias, #{Service.count} serviços)"

  catalog = Category.includes(:services).map { |c| [c, c.services.to_a] }.to_h
  non_empty_categories = catalog.select { |_c, svcs| svcs.any? }.keys
  raise "Não há categorias com serviços." if non_empty_categories.empty?

  # ---------- Users ----------
  puts "👤 Criando usuários…"

  # Main client
  client = User.find_or_initialize_by(email: "cliente@demo.com")
  client.password = "password"
  client.full_name = "Cliente Demo" if client.respond_to?(:full_name=)
  geo = sample_geo
  set_if_has(client, :city,       client.try(:city).presence    || geo[:city])
  set_if_has(client, :country,    client.try(:country).presence || geo[:country])
  set_if_has(client, :time_zone,  geo[:time_zone]) if client.has_attribute?(:time_zone)
  set_if_has(client, :avatar,     client.try(:avatar).presence  || stable_avatar_for(client.email))
  client.save!

  # Demo professional (owner of first WorkerProfile)
  pro_user = User.find_or_initialize_by(email: "pro@demo.com")
  pro_user.password = "password"
  pro_user.full_name = "Pro Test" if pro_user.respond_to?(:full_name=)
  geo = sample_geo
  set_if_has(pro_user, :city,      pro_user.try(:city).presence    || geo[:city])
  set_if_has(pro_user, :country,   pro_user.try(:country).presence || geo[:country])
  set_if_has(pro_user, :time_zone, geo[:time_zone]) if pro_user.has_attribute?(:time_zone)
  set_if_has(pro_user, :role, "worker") if pro_user.respond_to?(:role)
  set_if_has(pro_user, :worker, true)   if pro_user.has_attribute?(:worker)
  set_if_has(pro_user, :avatar,   pro_user.try(:avatar).presence   || stable_avatar_for(pro_user.email))
  pro_user.save!

  # Extra clients
  extra_clients = []
  (1..30).each do |i|
    email = "user%02d@demo.com" % i
    u = User.find_or_initialize_by(email: email)
    u.password ||= "password"
    set_brazilian_name!(u, force: true)
    geo = sample_geo
    set_if_has(u, :city,      u.try(:city).presence    || geo[:city])
    set_if_has(u, :country,   u.try(:country).presence || geo[:country])
    set_if_has(u, :time_zone, geo[:time_zone]) if u.has_attribute?(:time_zone)
    set_if_has(u, :avatar,    u.try(:avatar).presence  || stable_avatar_for(email))
    u.save!
    extra_clients << u
  end

  # ---------- Worker Profiles ----------
  puts "🧑‍🔧 Criando perfis de prestadores…"
  workers = []

  # Demo pro profile
  demo_cat = non_empty_categories.sample
  wp = WorkerProfile.find_or_initialize_by(user: pro_user)
  set_if_has(wp, :cpf,         wp.try(:cpf).presence         || uniq_cpf(1))
  desc = if defined?(Faker)
    "#{Faker::Job.title}. #{Faker::Company.buzzword.capitalize} • #{Faker::Lorem.sentence(word_count: 10)}"
  else
    "Profissional experiente. Atendimento de qualidade."
  end
  set_if_has(wp, :description, wp.try(:description).presence || desc)
  set_if_has(wp, :category_id, wp.try(:category_id).presence || demo_cat.id)
  wp.save!

  catalog[demo_cat].sample(3).each do |srv|
    WorkerService.find_or_create_by!(worker_profile: wp, service: srv) do |ws|
      ws.category     = demo_cat if ws.respond_to?(:category=)
      ws.service_type = %w[presencial remoto estabelecimento].sample if ws.respond_to?(:service_type=)
    end
  end
  workers << wp

  # +15 more pros with diverse geos
  (1..15).each do |i|
    email = "pro%02d@demo.com" % i
    owner = User.find_or_initialize_by(email: email)
    owner.password ||= "password"
    set_brazilian_name!(owner, force: true)
    geo = sample_geo
    set_if_has(owner, :city,      owner.try(:city).presence    || geo[:city])
    set_if_has(owner, :country,   owner.try(:country).presence || geo[:country])
    set_if_has(owner, :time_zone, geo[:time_zone]) if owner.has_attribute?(:time_zone)
    set_if_has(owner, :role, "worker") if owner.respond_to?(:role)
    set_if_has(owner, :worker, true)   if owner.has_attribute?(:worker)
    set_if_has(owner, :avatar,   owner.try(:avatar).presence   || stable_avatar_for(email))
    owner.save!

    cat = non_empty_categories.sample
    profile = WorkerProfile.find_or_initialize_by(user: owner)
    set_if_has(profile, :cpf,         profile.try(:cpf).presence         || uniq_cpf(i + 1))
    desc = if defined?(Faker)
      "#{cat.name} com experiência. #{Faker::Lorem.sentence(word_count: 12)}"
    else
      "#{cat.name} com experiência. Atuação em diversos serviços."
    end
    set_if_has(profile, :description, profile.try(:description).presence || desc)
    set_if_has(profile, :category_id, profile.try(:category_id).presence || cat.id)
    profile.save!

    catalog[cat].sample(3).each do |srv|
      WorkerService.find_or_create_by!(worker_profile: profile, service: srv) do |ws|
        ws.category     = cat if ws.respond_to?(:category=)
        ws.service_type = %w[presencial remoto estabelecimento].sample if ws.respond_to?(:service_type=)
      end
    end

    workers << profile
  end

  # ---------- Appointments ----------
  puts "📅 Criando agendamentos…"
  def make_appt!(client:, worker:, at:, status:)
    tz = worker.user.try(:time_zone) || client.try(:time_zone) || "America/Sao_Paulo"
    attrs = { user: client, worker_profile: worker, starts_at: at, status: status }
    appt = Appointment.new(attrs)
    set_if_has(appt, :time_zone, tz)
    # optional ends_at (~1h)
    if appt.respond_to?(:ends_at) && at.present?
      set_if_has(appt, :ends_at, at + 1.hour)
    end
    appt.save!
    appt
  end

  appts = []
  clients_pool = [client] + extra_clients

  # 6 accepted: 2 past, 2 today/tomorrow, 2 next week
  appts << make_appt!(client: clients_pool.sample, worker: workers[0],  at: (now - 3.days).change(hour: 10), status: "accepted")
  appts << make_appt!(client: clients_pool.sample, worker: workers[2],  at: (now - 1.day).change(hour: 15), status: "accepted")
  appts << make_appt!(client: client,              worker: workers[3],  at: now.change(hour: 17),            status: "accepted")
  appts << make_appt!(client: clients_pool.sample, worker: workers[4],  at: (now + 1.day).change(hour: 11),  status: "accepted")
  appts << make_appt!(client: clients_pool.sample, worker: workers[5],  at: (now + 6.days).change(hour: 10), status: "accepted")
  appts << make_appt!(client: clients_pool.sample, worker: workers[6],  at: (now + 7.days).change(hour: 14), status: "accepted")

  # 6 pending (2 with proposals)
  p1 = make_appt!(client: client,               worker: workers[7],  at: (now + 2.days).change(hour: 12), status: "pending")
  p2 = make_appt!(client: clients_pool.sample,  worker: workers[8],  at: (now + 3.days).change(hour: 9),  status: "pending")
  p3 = make_appt!(client: clients_pool.sample,  worker: workers[9],  at: (now + 4.days).change(hour: 18), status: "pending")
  p4 = make_appt!(client: clients_pool.sample,  worker: workers[10], at: (now + 5.days).change(hour: 16), status: "pending")
  p5 = make_appt!(client: clients_pool.sample,  worker: workers[11], at: (now + 2.days).change(hour: 13), status: "pending")
  p6 = make_appt!(client: clients_pool.sample,  worker: workers[12], at: (now + 3.days).change(hour: 19), status: "pending")

  # 3 declined
  appts << make_appt!(client: clients_pool.sample, worker: workers[13], at: (now + 2.days).change(hour: 15), status: "declined")
  appts << make_appt!(client: clients_pool.sample, worker: workers[1],  at: (now + 3.days).change(hour: 13), status: "declined")
  appts << make_appt!(client: clients_pool.sample, worker: workers[0],  at: (now + 4.days).change(hour: 10), status: "declined")

  # conflict for same worker (visual demo)
  conflict_a = make_appt!(client: clients_pool.sample, worker: workers[0], at: (now + 1.day).change(hour: 10),     status: "accepted")
  conflict_b = make_appt!(client: clients_pool.sample, worker: workers[0], at: (now + 1.day).change(hour: 10, min: 30), status: "accepted")
  appts += [p1, p2, p3, p4, p5, p6, conflict_a, conflict_b]

  # Proposals (if fields exist)
  if Appointment.new.respond_to?(:proposed_starts_at)
    p1.update!(proposed_starts_at: p1.starts_at + 2.hours, proposed_by_id: p1.worker_profile.user_id)
    p2.update!(proposed_starts_at: p2.starts_at - 1.hour, proposed_by_id: p2.user_id)
  end

  # ---------- Messages ----------
  puts "💬 Criando conversas…"
  appts.each do |appt|
    c = appt.user
    w = appt.worker_profile.user
    msgs = rand(6..10)
    author = [c, w].sample
    msgs.times do |i|
      author = (author == c) ? w : c
      txt = if i.zero?
        "Olá! Podemos confirmar #{lshort(appt.starts_at)}?"
      else
        if defined?(Faker) && Faker.const_defined?("Lorem")
          Faker::Lorem.sentence(word_count: rand(6..14))
        else
          "Mensagem de demonstração."
        end
      end
      make_message!(appt, author, txt)
    end

    # unread flags if columns exist (make index 'ping' light up)
    if appt.starts_at > now && %w[pending accepted].include?(appt.status.to_s)
      if [true, false].sample
        appt.update_column(:client_last_read_at, now)  if appt.respond_to?(:client_last_read_at)
        appt.update_column(:worker_last_read_at, nil)  if appt.respond_to?(:worker_last_read_at)
      else
        appt.update_column(:worker_last_read_at, now)  if appt.respond_to?(:worker_last_read_at)
        appt.update_column(:client_last_read_at, nil)  if appt.respond_to?(:client_last_read_at)
      end
    end
  end

  # ---------- Reviews ----------
  if defined?(Review)
    puts "⭐ Criando reviews realistas…"
    base_comments = [
      "Ótimo atendimento!", "Excelente comunicação e qualidade.",
      "Resolveu meu problema rapidamente.", "Profissional pontual e atencioso.",
      "Serviço de primeira.", "Voltarei a contratar."
    ]

    recent_time = -> do
      days_back = rand(0..90)
      (now - days_back.days).change(hour: rand(9..19), min: [0, 15, 30, 45].sample)
    end

    shaped_rating = -> do
      r = rand
      r < 0.10 ? 3 : (r < 0.65 ? 5 : 4) # mais 4–5, às vezes 3
    end

    workers.each do |wp|
      author_pool = ([client] + extra_clients).reject { |u| u.id == wp.user_id }.shuffle
      target = rand(4..7)
      used_ids = Review.where(worker_profile_id: wp.id).pluck(:user_id).to_set
      srv_names = wp.services.limit(3).pluck(:name)
      comment_for = -> do
        base = base_comments.sample
        if srv_names.any?
          "#{base} #{['para','no serviço de','durante'].sample} #{srv_names.sample.downcase}."
        else
          base
        end
      end

      author_pool.each do |author|
        break if Review.where(worker_profile_id: wp.id).count >= target
        next if used_ids.include?(author.id)
        rev = Review.find_or_initialize_by(worker_profile_id: wp.id, user_id: author.id)
        rev.rating  = shaped_rating.call
        rev.comment = comment_for.call
        # attach to most recent accepted appt (if you track appointment_id)
        appt_id = Appointment.where(worker_profile_id: wp.id, status: "accepted").order(:starts_at).last&.id
        set_if_has(rev, :appointment_id, appt_id)
        t = recent_time.call
        rev.created_at = t
        rev.updated_at = t
        rev.save!
        used_ids << author.id
      end

      while Review.where(worker_profile_id: wp.id).count < 3
        author = ([client] + extra_clients).sample
        next if author.id == wp.user_id
        next if Review.exists?(worker_profile_id: wp.id, user_id: author.id)
        t = recent_time.call
        Review.create!(
          worker_profile: wp,
          user: author,
          rating: shaped_rating.call,
          comment: base_comments.sample,
          appointment_id: Appointment.where(worker_profile_id: wp.id, status: "accepted").order(:starts_at).last&.id,
          created_at: t,
          updated_at: t
        )
      end
    end
  end

  # ---------- Summary ----------
  puts "\n✅ Seeds prontos!"
  puts "Users:        #{User.count}"
  puts "Workers:      #{WorkerProfile.count}"
  puts "Appointments: #{Appointment.count}  "\
       "(accepted: #{Appointment.where(status:'accepted').count}, "\
       "pending: #{Appointment.where(status:'pending').count}, "\
       "declined: #{Appointment.where(status:'declined').count})"
  puts "Messages:     #{defined?(Message) ? Message.count : 0}"
  puts "Services:     #{Service.count}"
  puts "Categories:   #{Category.count}"
  puts "Reviews:      #{defined?(Review) ? Review.count : 0}"
end
