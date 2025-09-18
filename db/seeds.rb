# db/seeds.rb — Brazilify demo (150 workers focados em 5 cidades + ~50 clients)
require "securerandom"
require "digest/md5"

# ---------- Optional Faker ----------
begin
  require "faker"
  Faker::Config.locale = "pt-BR"
rescue LoadError
  puts "⚠️  Gem 'faker' não encontrada (opcional; melhora textos)."
end

# ---------- Helpers de nomes/avatares ----------
MALE_FIRST = %w[
  André Bruno Carlos Daniel Eduardo Felipe Gabriel Henrique Igor Jorge
  Kleber Lucas Marcelo Natan Otávio Paulo Rafael Sérgio Tiago Vinícius Wagner
].freeze

FEMALE_FIRST = %w[
  Ana Bruna Camila Daniela Elisa Fernanda Gabriela Helena Isabela Júlia
  Karina Larissa Mariana Natália Olivia Patrícia Rafaela Sofia Thaís Vanessa Yasmin
].freeze

LAST_NAMES = %w[
  Silva Santos Oliveira Souza Rodrigues Almeida Nunes Lima Araújo Gomes
  Carvalho Rocha Barros Ribeiro Monteiro Duarte Batista Azevedo Correia Martins
].freeze

def person_name(gender)
  if defined?(Faker)
    first = (gender == :male) ? (Faker::Name.male_first_name rescue Faker::Name.first_name) :
                                (Faker::Name.female_first_name rescue Faker::Name.first_name)
    last  = Faker::Name.last_name
  else
    first = (gender == :male) ? MALE_FIRST.sample : FEMALE_FIRST.sample
    last  = LAST_NAMES.sample
  end
  "#{first} #{last}"
end

def gender_avatar_url(gender, index)
  base = (gender == :male) ? "men" : "women"
  n = index % 100
  "https://randomuser.me/api/portraits/#{base}/#{n}.jpg"
end

def stable_avatar_for(seed)
  n = (Digest::MD5.hexdigest(seed.to_s).to_i(16) % 70) + 1
  "https://i.pravatar.cc/150?img=#{n}"
end

def set_if_has(record, field, value)
  return if value.nil?
  if record.respond_to?(:"#{field}=")
    record.public_send(:"#{field}=", value)
  elsif record.has_attribute?(field)
    record[field] = value
  end
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

# ---------- GEO fixo (somente 5 cidades foco) ----------
# country, city, time_zone, latitude, longitude
WORLD_CITIES = [
  ["Portugal",        "Lisboa",   "Europe/Lisbon",  38.722252,   -9.139337],
  ["Portugal",        "Porto",    "Europe/Lisbon",  41.157944,   -8.629105],
  ["Ireland",         "Dublin",   "Europe/Dublin",  53.349805,   -6.260310],
  ["Ireland",         "Cork",     "Europe/Dublin",  51.898514,   -8.475604],
  ["United Kingdom",  "London",   "Europe/London",  51.507351,   -0.127758]
].freeze

# índice para (country,city) -> tz/lat/lon
GEO_INDEX = WORLD_CITIES.each_with_object({}) do |(country, city, tz, lat, lon), h|
  h[[country.downcase, city.downcase]] = { time_zone: tz, latitude: lat, longitude: lon }
end

def geo_for(country:, city:)
  GEO_INDEX[[country.to_s.downcase, city.to_s.downcase]]
end

# aplica country/city e força lat/lon exatos (bypass callbacks de geocoder)
def apply_geo!(user, country:, city:)
  g = geo_for(country: country, city: city)
  raise "Cidade não mapeada: #{city}, #{country}" unless g

  set_if_has(user, :country, country)
  set_if_has(user, :city,    city)
  user.save!
  user.update_columns(latitude: g[:latitude], longitude: g[:longitude])
end

# distribuição por peso (Lisboa 30%, London 25%, Dublin 20%, Porto 15%, Cork 10)
CITY_WEIGHTS = [
  ["Portugal","Lisboa",        30],
  ["United Kingdom","London",  25],
  ["Ireland","Dublin",         20],
  ["Portugal","Porto",         15],
  ["Ireland","Cork",           10]
].freeze

def pick_city_weighted
  total = CITY_WEIGHTS.sum { |_,_,w| w }
  x = rand(1..total)
  CITY_WEIGHTS.each do |country, city, w|
    return [country, city] if (x -= w) <= 0
  end
  ["Portugal","Lisboa"]
end

# ---------- Catálogo ----------
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

# ===================== EXECUÇÃO ======================
ActiveRecord::Base.transaction do
  now = Time.zone.now

  # -- Limpa dados dinâmicos em dev --
  if Rails.env.development?
    puts "🧹 Limpando dados (mantendo catálogo)…"
    Message.destroy_all        if defined?(Message)
    Review.destroy_all         if defined?(Review)
    Appointment.destroy_all    if defined?(Appointment)
    WorkerService.destroy_all  if defined?(WorkerService)
    WorkerProfile.destroy_all  if defined?(WorkerProfile)
    # não limpamos User pra manter logins se quiser
  end

  # -- Catálogo --
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

  # -- Clients (~50 não-workers) --
  puts "👤 Criando clients…"
  client = User.find_or_initialize_by(email: "cliente@demo.com")
  client.password = "password"
  client.full_name = "Cliente Demo"
  apply_geo!(client, country: "Portugal", city: "Lisboa")
  set_if_has(client, :avatar, client.try(:avatar).presence || stable_avatar_for(client.email))
  client.save!

  client_pool = [client]
  (1..49).each do |i|
    email = "client%02d@demo.com" % i
    u = User.find_or_initialize_by(email: email)
    u.password ||= "password"
    gen = i.odd? ? :female : :male
    u.full_name = person_name(gen)

    country, city = pick_city_weighted
    apply_geo!(u, country: country, city: city)
    set_if_has(u, :avatar, u.try(:avatar).presence || gender_avatar_url(gen, 200 + i))
    u.save!
    client_pool << u
  end
  puts "✅ Clients criados: #{client_pool.size}"

  # -- 150 Workers (75 M + 75 F) --
  puts "🛠️ Criando 150 prestadores (75 M + 75 F)…"
  workers = []

  make_desc = ->(cat) do
    if defined?(Faker)
      "#{cat.name} com experiência. #{Faker::Lorem.sentence(word_count: 12)}"
    else
      "#{cat.name} com experiência. Atuação em diversos serviços."
    end
  end

  def build_worker!(index:, gender:, non_empty_categories:, catalog:, make_desc:)
    email = "user%03d@demo.com" % index # user001..user150
    owner = User.find_or_initialize_by(email: email)
    owner.password ||= "password"
    owner.full_name = person_name(gender)

    # geo (pesos nas 5 cidades)
    country, city = pick_city_weighted
    apply_geo!(owner, country: country, city: city)

    set_if_has(owner, :avatar, owner.try(:avatar).presence || gender_avatar_url(gender, index))
    owner.save!

    cat = non_empty_categories.sample
    profile = WorkerProfile.find_or_initialize_by(user: owner)
    set_if_has(profile, :cpf,         profile.try(:cpf).presence || uniq_cpf(index))
    set_if_has(profile, :description, profile.try(:description).presence || make_desc.call(cat))
    set_if_has(profile, :category_id, profile.try(:category_id).presence || cat.id)
    profile.save!

    catalog[cat].sample(3).each do |srv|
      WorkerService.find_or_create_by!(worker_profile: profile, service: srv) do |ws|
        ws.category     = cat if ws.respond_to?(:category=)
        ws.service_type = %w[presencial remoto estabelecimento].sample if ws.respond_to?(:service_type=)
      end
    end

    profile
  end

  (1..75).each  { |i| workers << build_worker!(index: i,    gender: :male,   non_empty_categories: non_empty_categories, catalog: catalog, make_desc: make_desc) }
  (76..150).each{ |i| workers << build_worker!(index: i,    gender: :female, non_empty_categories: non_empty_categories, catalog: catalog, make_desc: make_desc) }
  puts "✅ Workers: #{WorkerProfile.count}"

  # -- Appointments (muitos para buscas e chats) --
  puts "📅 Criando agendamentos…"

  def make_appt!(client:, worker:, at:, status:)
    g = geo_for(country: worker.user.country, city: worker.user.city)
    tz = g ? g[:time_zone] : "Europe/Lisbon"

    tmp = at < Time.zone.now ? (Time.zone.now + 5.minutes) : at
    appt = Appointment.new(user: client, worker_profile: worker, starts_at: tmp, status: status)
    set_if_has(appt, :time_zone, tz)
    set_if_has(appt, :ends_at, tmp + 1.hour) if appt.respond_to?(:ends_at) && tmp.present?
    appt.save!

    if at < Time.zone.now
      updates = { starts_at: at }
      updates[:ends_at] = at + 1.hour if appt.respond_to?(:ends_at)
      appt.update_columns(updates) # bypass validations
    end
    appt
  end

  appts = []
  # base grande de agendas variadas
  220.times do
    wp   = workers.sample
    cli  = client_pool.sample
    day  = rand(-5..10)
    hour = [9,10,11,14,15,16,18,19].sample
    t    = (now + day.days).change(hour: hour)

    status = case rand
             when 0.0...0.55 then "accepted"
             when 0.55...0.85 then "pending"
             else "declined"
             end

    appts << make_appt!(client: cli, worker: wp, at: t, status: status)
  end

  # conflitos visuais (mesmo worker com overlap)
  12.times do
    wp   = workers.sample
    cli1 = client_pool.sample
    cli2 = (client_pool - [cli1]).sample
    base = (now + rand(1..3).days).change(hour: [10,11,14,15].sample)
    appts << make_appt!(client: cli1, worker: wp, at: base,              status: "accepted")
    appts << make_appt!(client: cli2, worker: wp, at: base + 30.minutes, status: "accepted")
  end

  # propostas (se colunas existirem)
  if Appointment.new.respond_to?(:proposed_starts_at)
    appts.sample(20).each do |a|
      next unless a.status.to_s == "pending"
      proposed_by_id = [a.user_id, a.worker_profile.user_id].sample
      a.update!(proposed_starts_at: a.starts_at + [1.hour, -1.hour, 2.hours].sample,
                proposed_by_id: proposed_by_id)
    end
  end

  # -- Mensagens (chats) --
  puts "💬 Criando conversas…"
  appts.each do |appt|
    c = appt.user
    w = appt.worker_profile.user
    msgs = rand(10..20)
    author = [c, w].sample
    msgs.times do |i|
      author = (author == c) ? w : c
      txt = if i.zero?
        "Olá! Podemos confirmar #{lshort(appt.starts_at)}?"
      else
        if defined?(Faker) && Faker.const_defined?("Lorem")
          Faker::Lorem.sentence(word_count: rand(7..16))
        else
          "Mensagem de demonstração."
        end
      end
      make_message!(appt, author, txt)
    end

    # unread flags (pra 'ping' no index)
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

  # -- Reviews --
  if defined?(Review)
    puts "⭐ Criando reviews…"
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
      r < 0.10 ? 3 : (r < 0.65 ? 5 : 4)
    end

    workers.each do |wp|
      # 4–7 reviews por worker
      target = rand(4..7)
      authors = client_pool.shuffle.take(target)

      srv_names = wp.services.limit(3).pluck(:name)
      comment_for = -> do
        base = base_comments.sample
        if srv_names.any?
          "#{base} #{['para','no serviço de','durante'].sample} #{srv_names.sample.downcase}."
        else
          base
        end
      end

      authors.each do |author|
        pair_appt = Appointment.where(user_id: author.id, worker_profile_id: wp.id, status: "accepted").order(:starts_at).last
        unless pair_appt
          t = (now - rand(3..20).days).change(hour: [10, 14, 16, 18].sample)
          pair_appt = make_appt!(client: author, worker: wp, at: t, status: "accepted")
        end

        next if Review.exists?(worker_profile_id: wp.id, user_id: author.id)

        t = recent_time.call
        Review.create!(
          worker_profile: wp,
          user: author,
          rating: shaped_rating.call,
          comment: comment_for.call,
          appointment_id: pair_appt.id,
          created_at: t,
          updated_at: t
        )
      end
    end
  end

  # -- Resumo / Logins --
  total_users = User.count
  total_workers = WorkerProfile.count
  total_clients = client_pool.size
  puts "\n✅ Seeds prontos!"
  puts "Users (total): #{total_users}"
  puts "Workers:       #{total_workers}"
  puts "Clients (não-workers): #{total_clients}"
  puts "Appointments:  #{Appointment.count}  " \
       "(accepted: #{Appointment.where(status:'accepted').count}, " \
       "pending: #{Appointment.where(status:'pending').count}, " \
       "declined: #{Appointment.where(status:'declined').count})"
  puts "Messages:      #{defined?(Message) ? Message.count : 0}"
  puts "Services:      #{Service.count}"
  puts "Categories:    #{Category.count}"
  puts "Reviews:       #{defined?(Review) ? Review.count : 0}"

  puts <<~LOGINS

  🔐 Logins de demo
  • Client principal:   cliente@demo.com / password
  • Clients extras:     client01@demo.com … client49@demo.com / password
  • Workers (M 1..75):  user001@demo.com … user075@demo.com / password
  • Workers (F 76..150): user076@demo.com … user150@demo.com / password
  LOGINS
end
