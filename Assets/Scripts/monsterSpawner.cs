using System.Collections.Generic;
using UnityEngine;

public class monsterSpawner : MonoBehaviour
{
    [System.Serializable]
    public class WaveContent
    {
        [SerializeField][NonReorderable] GameObject[] monsterSpawn;

        public GameObject[] GetMonsterSpawnList()
        {
            return monsterSpawn;
        }
    }

    [SerializeField][NonReorderable] WaveContent[] waves;
    [SerializeField] float minDistanceFromCenter = 200f;
    int currentWave = 0;
    float spawnRange = 80;
    public List<GameObject> currentMonster;

    void Start()
    {
        if (waves.Length > 0)
            SpawnWave();
        else
            Debug.LogWarning("Aucune vague définie dans le spawner !");
    }

    void Update()
    {
        if (currentMonster.Count == 0)
        {
            currentWave++;
            if (currentWave < waves.Length)
                SpawnWave();
            else
                Debug.Log("Toutes les vagues ont été spawnées !");
        }
    }

    void SpawnWave()
    {
        for (int i = 0; i < waves[currentWave].GetMonsterSpawnList().Length; i++)
        {
            GameObject newspawn = Instantiate(
                waves[currentWave].GetMonsterSpawnList()[i],
                FindSpawnLoc(),
                Quaternion.identity
            );
            currentMonster.Add(newspawn);

            Enemy monster = newspawn.GetComponent<Enemy>();
            if (monster != null)
            {
                monster.SetSpawner(this);
                // Définit la cible comme étant le point (0, 0, 0)
                monster.SetTarget(new GameObject("CenterTarget").transform);
                monster.SetTargetPosition(Vector3.zero);
            }
        }
    }

    Vector3 FindSpawnLoc()
    {
        Vector3 SpawnPos;
        float xLoc, zLoc;
        float yLoc = 0.75f;

        do
        {
            xLoc = Random.Range(-spawnRange, spawnRange) + transform.position.x;
            zLoc = Random.Range(-spawnRange, spawnRange) + transform.position.z;
            SpawnPos = new Vector3(xLoc, yLoc, zLoc);
        } while (!IsValidSpawnPosition(SpawnPos));

        return SpawnPos;
    }

    bool IsValidSpawnPosition(Vector3 position)
    {
        bool hasGround = Physics.Raycast(position, Vector3.down, 5);
        bool isFarFromCenter = Vector3.Distance(position, Vector3.zero) >= minDistanceFromCenter;
        return hasGround && isFarFromCenter;
    }
}