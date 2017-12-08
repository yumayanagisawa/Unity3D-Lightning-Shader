using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightningGenerator : MonoBehaviour {
    public Transform prefab;
    public int LightingFigures = 10;

	// Use this for initialization
	void Start () {
        for (int i = 0; i < LightingFigures; i++)
        {
            float x = Random.value - 0.5f;
            float y = Random.value - 0.5f;
            float z = Random.value - 0.5f;
            Vector3 pos = new Vector3(x, y, z) * 3.0f;
            pos.y *= 0.2f;
            Transform temp = Instantiate(prefab, pos, prefab.rotation);
            temp.GetComponent<Renderer>().material.SetFloat("_CustomTime", x * 20.0f);
        }
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
