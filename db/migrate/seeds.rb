u = User.create!(email: "demo@example.com", display_name: "Demo", password: "password")
d = u.owned_decks.create!(title: "Intro Biology", description: "Cell basics.")

c1 = d.cards.create!(front_text: "Mitochondria function?", back_text: "Powerhouse of the cell.")
c2 = d.cards.create!(front_text: "DNA stands for?", back_text: "Deoxyribonucleic acid.")

%w[bio basics].each { |t| c1.tags << Tag.find_or_create_by!(name: t) }
%w[genetics basics].each { |t| c2.tags << Tag.find_or_create_by!(name: t) }

[c1, c2].each do |card|
  CardProgress.create!(user: u, card: card, due_at: Time.current)
end

puts "Seeded: user=#{u.email}, deck=#{d.title}, cards=#{d.cards.count}"
