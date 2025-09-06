# db/seeds.rb — demo seed for Brazilify (workers, appointments, messages, reviews)
require "securerandom"
require "digest/md5"

# ---------------- Faker pt-BR (optional) ----------------
begin
  require "faker"
  Faker::Config.locale = "pt-BR"
rescue LoadError
  puts "⚠️  Gem 'faker' not found. Adicione no Gemfile (grupo :development) para nomes/textos melhores."
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
  n = (Digest::MD5.hexdigest(seed.to_s).to_i(16) % 70) + 1 # 1..70
  "https://i.pravatar.cc/150?img=#{n}"
end

def uniq_cpf(n)
  # 11 dígitos estáveis por índice (ok para demo)
  "%011d" % (9_000_000_000 + n)
end

def make_message!(appointment, author, text)
  Message.create!(appointment: appointment, user: author, content: text)
end

def lshort(t)
  I18n.l(t, format: :short) rescue t.strftime("%d/%m %H:%M")
end

# ---------------- Defaults & context ----------------
now     = Time.zone.now
cities  = %w[São\ Paulo Rio\ de\ Janeiro Belo\ Horizonte Curitiba Porto\ Alegre Recife]
country = "Brasil"

DEFAULT_CATALOG = {
  "Eletricista"          => ["Instalação", "Reparos", "Emergência 24h"],
  "Psicólogo"            => ["Sessão individual", "Casal", "Online"],
  "Encanador"            => ["Vazamentos", "Desentupimento", "Aquecedor"],
  "Diarista"             => ["Limpeza pesada", "Passadoria", "Faxina semanal"],
  "Professor de Inglês"  => ["Aula 1:1", "Conversação", "Preparação IELTS"],
  "Personal Trainer"     => ["Avaliação", "Treino funcional", "Em casa"]
}.freeze

ActiveRecord::Base.transaction do
  # ---------- Clean (dev): rebuild workers/appointments/messages/reviews only ----------
  if Rails.env.development?
    puts "🧹 Limpando dados de demo (mantendo usuários e catálogo)…"
    Message.destroy_all        if defined?(Message)
    Review.destroy_all         if defined?(Review)
    Appointment.destroy_all    if defined?(Appointment)
    WorkerService.destroy_all  if defined?(WorkerService)
    WorkerProfile.destroy_all  if defined?(WorkerProfile)
  end

  # ---------- Catalog (keep yours; create defaults if empty) ----------
  puts "📚 Verificando catálogo…"
  if Category.count.zero? || Service.count.zero?
    puts "➕ Criando catálogo padrão (pois estava vazio)…"
    DEFAULT_CATALOG.each do |cat_name, services|
      cat = Category.find_or_create_by!(name: cat_name)
      services.each { |srv| Service.find_or_create_by!(name: srv, category: cat) }
    end
  else
    puts "✅ Usando categorias/serviços existentes (#{Category.count} categorias, #{Service.count} serviços)."
  end

  catalog = Category.includes(:services).map { |c| [c, c.services.to_a] }.to_h
  non_empty_categories = catalog.select { |_c, svcs| svcs.any? }.keys
  raise "Não há categorias com serviços." if non_empty_categories.empty?

  # ---------- Users (deterministic emails) ----------
  puts "👤 Criando usuários demo…"
  client = User.find_or_initialize_by(email: "cliente@demo.com")
  client.password = "password"
  client.full_name = "Cliente Demo" if client.respond_to?(:full_name=)
  set_if_has(client, :city,    client.try(:city).presence    || cities.sample)
  set_if_has(client, :country, client.try(:country).presence || country)
  set_if_has(client, :avatar,  client.try(:avatar).presence  || stable_avatar_for(client.email))
  client.save!

  pro_user = User.find_or_initialize_by(email: "pro@demo.com")
  pro_user.password = "password"
  pro_user.full_name = "Pro Test" if pro_user.respond_to?(:full_name=)
  set_if_has(pro_user, :city,    pro_user.try(:city).presence    || "São Paulo")
  set_if_has(pro_user, :country, pro_user.try(:country).presence || country)
  set_if_has(pro_user, :role, "worker") if pro_user.respond_to?(:role)
  set_if_has(pro_user, :worker, true)   if pro_user.has_attribute?(:worker)
  set_if_has(pro_user, :avatar,  pro_user.try(:avatar).presence  || stable_avatar_for(pro_user.email))
  pro_user.save!

  # 20 extra clients with fixed emails (idempotent)
  extra_clients = []
  (1..20).each do |i|
    email = "user%02d@demo.com" % i
    u = User.find_or_initialize_by(email: email)
    u.password ||= "password"
    set_brazilian_name!(u, force: true)
    set_if_has(u, :city,    u.try(:city).presence    || cities.sample)
    set_if_has(u, :country, u.try(:country).presence || country)
    set_if_has(u, :avatar,  u.try(:avatar).presence  || stable_avatar_for(email))
    u.save!
    extra_clients << u
  end

  # ---------- WorkerProfiles (12 total) ----------
  puts "🧑‍🔧 Criando perfis de prestadores…"
  workers = []

  # demo pro profile
  demo_cat = non_empty_categories.sample
  wp = WorkerProfile.find_or_initialize_by(user: pro_user)
  set_if_has(wp, :cpf,          wp.try(:cpf).presence          || uniq_cpf(1))
  set_if_has(wp, :description,  wp.try(:description).presence  || "Profissional experiente. #{(defined?(Faker) ? Faker::Lorem.sentence(word_count: 10) : 'Atendimento de qualidade.')}")
  set_if_has(wp, :category_id,  wp.try(:category_id).presence  || demo_cat.id)
  wp.save!

  # attach 3 services w/ valid service_type + category
  catalog[demo_cat].sample(3).each do |srv|
    WorkerService.find_or_create_by!(worker_profile: wp, service: srv) do |ws|
      ws.category     = demo_cat
      ws.service_type = %w[presencial remoto estabelecimento].sample
    end
  end
  workers << wp

  # +11 more pros (pro01..pro11), always real names + avatars
  (1..11).each do |i|
    email = "pro%02d@demo.com" % i
    owner = User.find_or_initialize_by(email: email)
    owner.password ||= "password"
    set_brazilian_name!(owner, force: true)
    set_if_has(owner, :city,    owner.try(:city).presence    || cities.sample)
    set_if_has(owner, :country, owner.try(:country).presence || country)
    set_if_has(owner, :role, "worker") if owner.respond_to?(:role)
    set_if_has(owner, :worker, true)   if owner.has_attribute?(:worker)
    set_if_has(owner, :avatar,  owner.try(:avatar).presence  || stable_avatar_for(email))
    owner.save!

    cat = non_empty_categories.sample
    profile = WorkerProfile.find_or_initialize_by(user: owner)
    set_if_has(profile, :cpf,          profile.try(:cpf).presence          || uniq_cpf(i + 1))
    set_if_has(profile, :description,  profile.try(:description).presence  || "#{cat.name} com experiência. #{(defined?(Faker) ? Faker::Lorem.sentence(word_count: 12) : 'Atuação em diversos serviços.')}")
    set_if_has(profile, :category_id,  profile.try(:category_id).presence  || cat.id)
    profile.save!

    catalog[cat].sample(3).each do |srv|
      WorkerService.find_or_create_by!(worker_profile: profile, service: srv) do |ws|
        ws.category     = cat
        ws.service_type = %w[presencial remoto estabelecimento].sample
      end
    end

    workers << profile
  end

  # ---------- Appointments ----------
  puts "📅 Criando agendamentos…"
  def make_appt!(client:, worker:, at:, status:)
    Appointment.create!(user: client, worker_profile: worker, starts_at: at, status: status)
  end

  appts = []
  any_client = -> { ([User.find_by(email: "cliente@demo.com")] + User.where("email LIKE 'user%@@demo.com'")).presence || User.where("email LIKE 'user%@@demo.com'") }
  # safer any_client:
  clients_pool = [client] + extra_clients

  # 6 accepted: 2 past, 2 today/tomorrow, 2 next week
  appts << make_appt!(client: clients_pool.sample, worker: wp,           at: now - 3.days + 10.hours, status: "accepted")
  appts << make_appt!(client: clients_pool.sample, worker: workers[2],   at: now - 1.day + 15.hours,  status: "accepted")
  appts << make_appt!(client: client,              worker: workers[3],   at: now.change(hour: 17),    status: "accepted")
  appts << make_appt!(client: clients_pool.sample, worker: workers[4],   at: (now + 1.day).change(hour: 11), status: "accepted")
  appts << make_appt!(client: clients_pool.sample, worker: workers[5],   at: (now + 6.days).change(hour: 10), status: "accepted")
  appts << make_appt!(client: clients_pool.sample, worker: workers[6],   at: (now + 7.days).change(hour: 14), status: "accepted")

  # 4 pending (2 with proposals)
  p1 = make_appt!(client: client,               worker: workers[7],  at: (now + 2.days).change(hour: 12), status: "pending")
  p2 = make_appt!(client: clients_pool.sample,  worker: workers[8],  at: (now + 3.days).change(hour: 9),  status: "pending")
  p3 = make_appt!(client: clients_pool.sample,  worker: workers[9],  at: (now + 4.days).change(hour: 18), status: "pending")
  p4 = make_appt!(client: clients_pool.sample,  worker: workers[10], at: (now + 5.days).change(hour: 16), status: "pending")

  # 2 declined
  appts << make_appt!(client: clients_pool.sample, worker: workers[11], at: (now + 2.days).change(hour: 15), status: "declined")
  appts << make_appt!(client: clients_pool.sample, worker: workers.first, at: (now + 3.days).change(hour: 13), status: "declined")

  # conflict for the same worker (wp)
  conflict_a = make_appt!(client: clients_pool.sample, worker: wp, at: (now + 1.day).change(hour: 10), status: "accepted")
  conflict_b = make_appt!(client: clients_pool.sample, worker: wp, at: (now + 1.day).change(hour: 10, min: 30), status: "accepted")
  appts += [p1, p2, p3, p4, conflict_a, conflict_b]

  # reschedule proposals (only if columns exist)
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
          Faker::Lorem.sentence(word_count: rand(5..12))
        else
          "Mensagem de demonstração."
        end
      end
      make_message!(appt, author, txt)
    end

    # unread flags if columns exist
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

  # ---------- Reviews (realistic dates + shaped ratings + service mention) ----------
  if defined?(Review)
    puts "⭐ Criando reviews realistas…"
    base_comments = [
      "Ótimo atendimento!",
      "Excelente comunicação e qualidade.",
      "Resolveu meu problema rapidamente.",
      "Profissional pontual e atencioso.",
      "Serviço de primeira.",
      "Voltarei a contratar."
    ]

    # helper: random recent time within 90 days
    recent_time = -> do
      days_back = rand(0..90)
      (now - days_back.days).change(hour: rand(9..19), min: [0, 15, 30, 45].sample)
    end

    # helper: biased rating (mostly 4–5, rare 3)
    shaped_rating = -> do
      r = rand
      r < 0.10 ? 3 : (r < 0.65 ? 5 : 4)
    end

    workers.each do |wp|
      # authors: client demo + extras, never the worker
      author_pool = ([client] + extra_clients).reject { |u| u.id == wp.user_id }.shuffle

      # target 4–7 reviews per worker
      target = rand(4..7)

      # already used authors (make idempotent)
      used_ids = Review.where(worker_profile_id: wp.id).pluck(:user_id).to_set

      # build comments that mention one of the worker's services (if any)
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
        rev.created_at = recent_time.call
        rev.updated_at = rev.created_at
        rev.save!

        used_ids << author.id
      end

      # ensure at least 3 even if author_pool small
      while Review.where(worker_profile_id: wp.id).count < 3
        author = ([client] + extra_clients).sample
        next if author.id == wp.user_id
        next if Review.exists?(worker_profile_id: wp.id, user_id: author.id)

        Review.create!(
          worker_profile: wp,
          user: author,
          rating: shaped_rating.call,
          comment: base_comments.sample,
          created_at: recent_time.call,
          updated_at: recent_time.call
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
