class AddPredefinedServices < ActiveRecord::Migration[7.1]
  def change
    services_by_category = {
      "Construção" => ["Pedreiro", "Pintura", "Eletricista"],

      "Tecnologia" => ["Suporte de TI", "Criação de Sites", "Designer"],

      "Beleza / Estética" => [
        "Cabeleireiro", "Manicure", "Maquiagem",
        "Corte feminino/masculino/infantil",
        "Escova/chapinha/babyliss",
        "Coloração e mechas",
        "Progressiva/alisamento",
        "Hidratação e tratamentos capilares",
        "Alongamento de unhas (gel, fibra, acrílico)",
        "Nail art personalizada",
        "Limpeza de pele",
        "Design de sobrancelhas",
        "Micropigmentação",
        "Extensão de cílios",
        "Drenagem linfática",
        "Massagem modeladora",
        "Depilação (cera, laser, linha)",
        "Bronzeamento artificial",
        "Tratamentos para celulite/estrias",
        "Massagem relaxante",
        "Aromaterapia",
        "Reflexologia",
        "Spa day completo"
      ],

      "Serviços Automotivos" => [
        "Troca de óleo e filtros",
        "Revisão preventiva",
        "Mecânica de motores",
        "Suspensão e freios",
        "Diagnóstico eletrônico",
        "Bateria e alternador",
        "Instalação de som e acessórios",
        "Funilaria e pintura",
        "Recuperação de amassados",
        "Polimento técnico",
        "Lavagem completa (interna/externa)",
        "Higienização de estofados",
        "Cristalização e vitrificação da pintura",
        "Envelopamento e adesivagem",
        "Troca de pneus e balanceamento",
        "Alinhamento",
        "Troca de lâmpadas e palhetas",
        "Ar-condicionado automotivo",
        "Blindagem e manutenção",
        "Instalação de película (insulfilm)",
        "Reparo de vidros"
      ],

      "Manutenção Residencial" => [
        "Encanador",
        "Eletricista",
        "Montagem de Móveis",
        "Marcenaria",
        "Instalação de Ar-Condicionado",
        "Reparos em Drywall/Gesso",
        "Chaveiro",
        "Dedetização",
        "Instalação de Portas e Janelas",
        "Reparo de Telhados",
        "Jardinagem",
        "Paisagismo",
        "Serviços de Pintura",
        "Instalação de Cortinas e Persianas",
        "Reforma de Banheiros e Cozinhas"
      ],

      "Saúde e Bem-estar" => [
        "Personal Trainer",
        "Nutricionista",
        "Fisioterapeuta",
        "Massoterapeuta",
        "Psicólogo"
      ],

      "Educação" => [
        "Reforço Escolar",
        "Aulas de Idiomas",
        "Aulas de Música",
        "Aulas de Dança",
        "Preparatório para Concursos"
      ],

      "Transporte e Logística" => [
        "Motorista Particular",
        "Motoboy",
        "Frete/Carretos",
        "Transporte Escolar",
        "Entregador"
      ],

      "Serviços Domésticos" => [
        "Diarista",
        "Passadeira",
        "Babá",
        "Cuidador de Idosos",
        "Lavanderia"
      ],

      "Eventos" => [
        "Fotógrafo",
        "Filmagem",
        "DJ",
        "Buffet",
        "Decorador"
      ],

      "Animais de Estimação" => [
        "Passeador de Cães",
        "Adestrador",
        "Pet Sitter",
        "Banho e Tosa",
        "Hospedagem"
      ],

      "Administração / Negócios" => [
        "Consultoria Financeira",
        "Contador",
        "Marketing Digital",
        "Gestão de Redes Sociais",
        "Consultoria Jurídica"
      ],

      "Arte e Artesanato" => [
        "Costureira",
        "Bordado/Pintura em Tecido",
        "Artesanato Personalizado",
        "Restauração de Móveis",
        "Designer de Joias"
      ]
    }

    services_by_category.each do |category_name, services|
      category = Category.find_by(name: category_name)
      next unless category

      services.each do |service_name|
        Service.find_or_create_by!(name: service_name, category: category)
      end
    end
  end
end
