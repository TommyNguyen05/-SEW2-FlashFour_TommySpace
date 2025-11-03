require "test_helper"

class DecksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @deck = decks(:one)
    sign_in @user
  end

  test "should export deck as JSON" do
    get export_deck_path(@deck)
    
    assert_response :success
    assert_equal 'application/json', response.content_type
    
    # Parse the JSON response
    json_data = JSON.parse(response.body)
    
    # Verify structure
    assert json_data.key?('deck')
    assert json_data.key?('flashcards')
    assert_equal @deck.title, json_data['deck']['title']
    assert_equal @deck.description, json_data['deck']['description']
    
    # Verify flashcards
    assert_equal @deck.flashcards.count, json_data['flashcards'].length
    
    # Verify first flashcard
    first_card = @deck.flashcards.first
    first_exported = json_data['flashcards'].first
    assert_equal first_card.front_text, first_exported['front_text']
    assert_equal first_card.back_text, first_exported['back_text']
  end

  test "should import deck from JSON" do
    json_data = {
      deck: {
        title: "Test Import Deck",
        description: "Test description"
      },
      flashcards: [
        { front_text: "Question 1", back_text: "Answer 1" },
        { front_text: "Question 2", back_text: "Answer 2" }
      ]
    }.to_json

    # Create a temporary file
    file = Tempfile.new(['test', '.json'])
    begin
      file.write(json_data)
      file.rewind

      uploaded_file = Rack::Test::UploadedFile.new(file.path, 'application/json')

      assert_difference('Deck.count', 1) do
        assert_difference('Flashcard.count', 2) do
          post import_decks_path, params: {
            deck: {
              title: "Imported Deck",
              description: "Imported description",
              file: uploaded_file
            }
          }
        end
      end

      assert_response :redirect
      
      # Find the newly created deck
      new_deck = Deck.order(created_at: :desc).first
      assert_equal "Imported Deck", new_deck.title
      assert_equal 2, new_deck.flashcards.count
      
      # Verify flashcards
      assert_equal "Question 1", new_deck.flashcards.first.front_text
      assert_equal "Answer 1", new_deck.flashcards.first.back_text
    ensure
      file.close
      file.unlink
    end
  end

  test "should reject invalid JSON on import" do
    file = Tempfile.new(['test', '.json'])
    begin
      file.write("{ invalid json }")
      file.rewind

      uploaded_file = Rack::Test::UploadedFile.new(file.path, 'application/json')

      assert_no_difference('Deck.count') do
        post import_decks_path, params: {
          deck: {
            title: "Test Deck",
            description: "Test",
            file: uploaded_file
          }
        }
      end

      assert_response :unprocessable_entity
      assert_select '.error-messages'
    ensure
      file.close
      file.unlink
    end
  end

  test "should reject JSON without flashcards array" do
    json_data = {
      deck: { title: "Test" }
    }.to_json

    file = Tempfile.new(['test', '.json'])
    begin
      file.write(json_data)
      file.rewind

      uploaded_file = Rack::Test::UploadedFile.new(file.path, 'application/json')

      assert_no_difference('Deck.count') do
        post import_decks_path, params: {
          deck: {
            title: "Test Deck",
            description: "Test",
            file: uploaded_file
          }
        }
      end

      assert_response :unprocessable_entity
    ensure
      file.close
      file.unlink
    end
  end

  test "should handle export and import round trip" do
    # Export deck
    get export_deck_path(@deck)
    assert_response :success
    
    exported_data = response.body
    json_data = JSON.parse(exported_data)
    
    # Verify exported data
    assert_equal @deck.flashcards.count, json_data['flashcards'].length
    
    # Import the exported data
    file = Tempfile.new(['test', '.json'])
    begin
      file.write(exported_data)
      file.rewind

      uploaded_file = Rack::Test::UploadedFile.new(file.path, 'application/json')

      initial_deck_count = Deck.count
      initial_card_count = Flashcard.count
      original_card_count = @deck.flashcards.count

      post import_decks_path, params: {
        deck: {
          title: "Imported Copy",
          description: "Imported from export",
          file: uploaded_file
        }
      }

      assert_equal initial_deck_count + 1, Deck.count
      assert_equal initial_card_count + original_card_count, Flashcard.count
      
      # Verify the imported deck has the same cards
      new_deck = Deck.order(created_at: :desc).first
      assert_equal original_card_count, new_deck.flashcards.count
      
      # Verify card contents match
      original_cards = @deck.flashcards.order(:id)
      imported_cards = new_deck.flashcards.order(:id)
      
      original_cards.zip(imported_cards).each do |original, imported|
        assert_equal original.front_text, imported.front_text
        assert_equal original.back_text, imported.back_text
      end
    ensure
      file.close
      file.unlink
    end
  end
end
