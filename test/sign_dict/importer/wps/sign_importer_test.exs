defmodule SignDict.Importer.Wps.SignImporterTest do
  use SignDict.ModelCase
  import SignDict.Factory

  alias SignDict.Importer.Wps.SignImporter
  alias SignDict.Importer.ImporterConfig
  alias SignDict.Repo
  alias SignDict.Video

  describe "import_json/1" do
    setup do
      entry = insert(:entry, %{text: "Zug"})
      user = insert(:user, %{name: "WPS"})

      Repo.insert!(%Video{
        copyright: "sign2mint",
        license: "by-nc-sa/3.0/de",
        original_href: "https://delegs.de/",
        metadata: %{
          source_json: %{
            "videoUrl" => "http://localhost:8081/videos/Zug.mp4",
            "documentId" => "123123123:12",
            "metadata" => %{
              "Fachbegriff" => "Zug"
            }
          },
          source_mp4: "source.mp4"
        },
        user: user,
        entry: entry,
        state: "uploaded",
        external_id: "123123123:12",
        auto_publish: true,
        video_url: "http://localhost:8081/videos/Zug.mp4"
      })

      {:ok, entry: entry, user: user}
    end

    test "it imports the data into the video" do
      videos = SignImporter.import_json()

      assert length(videos) == 1

      video = List.first(videos)

      assert video.metadata["source_sign_json"] ==
               %{
                 "documentId" => "4347009787320352:59",
                 "gebaerdenSchriftUrl" => ["http://localhost:8081/images/russland.png"],
                 "videoUrl" => ["http://localhost:8081/videos/Zug.mp4"],
                 "metadata" => %{
                   "Anwendungsbereich:" => ["Akademie", "Schule"],
                   "Aufnahmedatum:" => "2019-09-23 00:00:00",
                   "Bedeutungsnummer:" => "1",
                   "CC / Ort:" => "MPI",
                   "Empfehlung:" => "",
                   "Fachbegriff" => "Zug",
                   "Fachgebiet:" => ["Chemie", "Geowissenschaft", "Informatik"],
                   "Filmproduzent:" => "Jung-Woo Kim",
                   "Freigabedatum:" => "",
                   "Gebärdender:" => "Robert Jasko",
                   "Herkunft:" => ["neu", "international"],
                   "Hochladedatum:" => "2020-03-23 00:00:00",
                   "Sprache:" => ["DGS", "BSL"],
                   "Wikipedia:" => "https://de.wikipedia.org/wiki/Anorganische_Chemie",
                   "Wiktionary:" => "https://de.wiktionary.org/wiki/anorganisch"
                 }
               }

      assert File.exists?(
               Path.join([
                 "uploads",
                 "video_sign_writing",
                 "#{video.id}",
                 "original.png"
               ])
             )

      config = ImporterConfig.for("WPS-Sign")
      {:ok, last_parsed} = Timex.parse(config.configuration["last_requested"], "{ISO:Extended:Z}")

      assert DateTime.compare(last_parsed, Timex.shift(Timex.now(), minutes: -1)) == :gt
    end

    test "it does not crash if the video url does not exist" do
      start_time = Timex.parse!("2020-06-01T12:30:30+00:00", "%FT%T%:z", :strftime)

      %ImporterConfig{}
      |> ImporterConfig.changeset(%{
        name: "WPS-Sign",
        configuration: %{last_requested: start_time}
      })
      |> Repo.insert!()

      videos = SignImporter.import_json()
      assert length(videos) == 0
    end

    test "it does not crash it there is no sign writing" do
      start_time = Timex.parse!("2020-02-01T12:30:30+00:00", "%FT%T%:z", :strftime)

      %ImporterConfig{}
      |> ImporterConfig.changeset(%{
        name: "WPS-Sign",
        configuration: %{last_requested: start_time}
      })
      |> Repo.insert!()

      videos = SignImporter.import_json()
      assert length(videos) == 0
    end

    test "it does not crash if the sign writing is empty" do
      start_time = Timex.parse!("2020-03-01T12:30:30+00:00", "%FT%T%:z", :strftime)

      %ImporterConfig{}
      |> ImporterConfig.changeset(%{
        name: "WPS-Sign",
        configuration: %{last_requested: start_time}
      })
      |> Repo.insert!()

      videos = SignImporter.import_json()
      assert length(videos) == 0
    end

    test "it requests the videos with the last processing time" do
      start_time = Timex.parse!("2020-01-01T12:30:30+00:00", "%FT%T%:z", :strftime)

      %ImporterConfig{}
      |> ImporterConfig.changeset(%{
        name: "WPS-Sign",
        configuration: %{last_requested: start_time}
      })
      |> Repo.insert!()

      videos = SignImporter.import_json()
      assert length(videos) == 0
    end

    test "does not crash on empty response via the api" do
      start_time = Timex.parse!("2020-04-01T12:30:30+00:00", "%FT%T%:z", :strftime)

      %ImporterConfig{}
      |> ImporterConfig.changeset(%{
        name: "WPS-Sign",
        configuration: %{last_requested: start_time}
      })
      |> Repo.insert!()

      videos = SignImporter.import_json()
      assert length(videos) == 0
    end

    test "it does not deleted the file if it is marked for deletion" do
      start_time = Timex.parse!("2020-05-01T12:30:30+00:00", "%FT%T%:z", :strftime)

      %ImporterConfig{}
      |> ImporterConfig.changeset(%{
        name: "WPS-Sign",
        configuration: %{last_requested: start_time}
      })
      |> Repo.insert!()

      videos = SignImporter.import_json()
      assert length(videos) == 0
    end
  end
end
